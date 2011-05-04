module CarrierWave
  module Mount
    class Mounter
      def uploader
        @uploader ||= record.uploaders[column].new(record, column) if record.respond_to?(:uploaders)
        @uploader ||= record.class.uploaders[column].new(record, column)
        if @uploader.blank? and not identifier.blank?
          @uploader.retrieve_from_store!(identifier)
        end
        return @uploader
      end
      
      private
      def option(name)
        if record.respond_to?(:uploader_options) && record.uploader_options.has_key?(column)
          if record.uploader_options[column].has_key?(name)
            record.uploader_options[column][name]
          else
            record.uploader_options[column].send(name)
          end
        else
          record.class.uploader_option(column, name)
        end
      end
    end
  end
end

#
# TODO: Monkey-patch more nicely!
#

#module CarrierWave
#  module Mount
#    module MetaClassMounter
#      def self.included(base)
#        base.send(:include, InstanceMethods)
#      end
#      
#      module InstanceMethods
#        def uploader
#          if record.respond_to?(:uploaders)
#            @uploader ||= record.uploaders[column].new(record, column)
#          end
#          super
#        end
#      
#        private
#        def option(name)
#          if record.respond_to?(:uploader_options) && record.uploader_options.has_key?(column)
#            if record.uploader_options[column].has_key?(name)
#              record.uploader_options[column][name]
#            else
#              record.uploader_options[column].send(name)
#            end
#          else
#            super
#          end
#        end
#      end
#    end
#  end
#end
#
#CarrierWave::Mount::Mounter.send(:include, CarrierWave::Mount::MetaClassMounter)