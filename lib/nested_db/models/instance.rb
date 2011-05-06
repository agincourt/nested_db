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
          
          # pagination
          cattr_reader :per_page
          @@per_page = 20
          
          # associations
          referenced_in :taxonomy, :inverse_of => :instances, :class_name => "NestedDb::Taxonomy"
          
          # validation
          validates_presence_of :taxonomy
          validate :validate_against_taxonomy, :if => proc { |obj| obj.taxonomy.present? }
          
          # callbacks
          after_validation  :process_rich_text
        end
        
        base.send(:include, InstanceMethods)
        base.send(:include, DynamicAttributes)
      end
      
      module ClassMethods
        def image_variation(input, variation = nil)
          input = input.url if input.kind_of?(CarrierWave::Uploader::Base)
          input.gsub!(/^(.*)\/(.*?)(\?\d+)?$/, "\\1/#{variation.to_s}_\\2") if variation
          input
        end
      end
      
      module InstanceMethods
        def versions(mounted_as)
          # if the taxonomy doesn't have this property, return blank hash
          return {} unless taxonomy.has_property?(mounted_as)
          # load the property
          property = taxonomy.properties[mounted_as.to_s]
          # map the versions into a hash
          (property.try(:image_versions) || []).inject({}) { |result,iv|
            result.merge(iv.name => "process :#{iv.operation} => [#{iv.width},#{iv.height}]")
          }
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
        
        def validate_against_taxonomy
          taxonomy.validate_instance(self)
        end
      end
    end
  end
end