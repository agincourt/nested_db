module NestedDb
  module Models
    module Instance
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.send(:include, ::Mongoid::Timestamps)
        base.send(:include, ::Mongoid::Paranoia)
        base.send(:include, ::Mongoid::MultiParameterAttributes)
        
        base.class_eval do
          extend ClassMethods
          
          # we don't want the delegation method
          remove_method :fields
          
          # associations
          referenced_in :taxonomy, :inverse_of => :instances, :class_name => "NestedDb::Taxonomy"
          
          # validation
          validates_presence_of :taxonomy
          validate :validate_against_taxonomy, :if => proc { |obj| obj.taxonomy.present? }
          
          # callbacks
          before_validation :process_has_many_associations
          after_validation  :process_rich_text
          after_validation  :process_file_uploads
        end
        
        base.send(:include, InstanceMethods)
        base.send(:include, DynamicAttributes)
        base.send(:include, DynamicAssociations)
      end
      
      module ClassMethods
        def image_variation(input, variation = nil)
          input.gsub!(/^(.*)\/(.*?)(\?\d+)?$/, "\\1/#{variation.to_s}_\\2") if variation
          input
        end
      end
      
      module InstanceMethods
        def fields
          self.class.fields
        end
        
        private
        # process the rich text fields into HTML
        def process_rich_text
          taxonomy.physical_properties.where(:data_type => 'rich_text').each do |pp|
            if self.send(pp.name).present?
              write_attribute("#{pp.name}_rich_text_processed", RedCloth.new(self.send(pp.name)).to_html)
            end
          end
        end
        
        # process the uploaded files
        def process_file_uploads
          (@pending_files || {}).each do |name,file|
            uploader = NestedDb::InstanceFileUploader.new(self, name)
            uploader.store!(file)
            write_attribute(name, uploader.url)
          end
        end
        
        def validate_against_taxonomy
          taxonomy.validate_instance(self)
        end
      end
    end
  end
end