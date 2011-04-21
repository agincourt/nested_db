module NestedDb
  module Models
    module Instance
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.send(:include, ::Mongoid::Timestamps)
        base.send(:include, ::Mongoid::Paranoia)
        base.send(:include, ::Mongoid::MultiParameterAttributes)
        
        base.class_eval do
          # we don't want the delegation method
          remove_method :fields
          
          # associations
          referenced_in :taxonomy, :inverse_of => :instances, :class_name => "NestedDb::Taxonomy"
          
          # validation
          validates_presence_of :taxonomy
          validate :validate_against_taxonomy, :if => proc { |obj| obj.taxonomy.present? }
          
          # callbacks
          after_validation :process_rich_text
          after_validation :process_file_uploads
        end
        
        base.send(:include, InstanceMethods)
      end
      
      module InstanceMethods
        # allows for readers when the attribute hasn't been
        # physically defined yet
        def method_missing(method, *args)
          if taxonomy && taxonomy.has_property?(method)
            read_attribute(method)
          elsif taxonomy && method.to_s =~ /^(.*)\=$/ && taxonomy.has_file_property?($1)
            write_file_attribute($1, args.first)
          else
            super(method, args)
          end
        end
        
        # stores files temporarily for processing
        def write_file_attribute(name, value)
          # store the file
          @pending_files ||= {}
          @pending_files.merge!(name => value)
          # write the value
          write_attribute(name, value)
        end
        
        # allows for typecasting on the dynamic taxonomy fields
        def fields
          self.class.fields.reverse_merge(taxonomy.try(:property_fields) || {})
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