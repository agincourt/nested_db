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
          
          attr_accessor :ignore_errors
          
          # pagination
          cattr_reader :per_page
          @@per_page = 20
          
          # fields
          field :auto_incremented_id, :type => Integer
          
          # associations
          belongs_to :taxonomy,
            :inverse_of => :instances,
            :class_name => "NestedDb::Taxonomy"
          
          # validation
          validates_presence_of :taxonomy
          validate :validate_against_taxonomy, :if => proc { |obj| obj.taxonomy.present? }
          
          # callbacks
          after_validation :generate_auto_incremented_id
          after_validation :process_rich_text
          after_validation :process_virtual_properties
        end
        
        base.send(:include, InstanceMethods)
        base.send(:include, DynamicAttributes)
      end
      
      module ClassMethods
        def image_variation(input, variation = nil)
          input ||= ''
          input = input.url if input.kind_of?(CarrierWave::Uploader::Base)
          input.gsub!(/^(.*)\/(.*?)(\?\d+)?$/, "\\1/#{variation.to_s}_\\2") if variation
          input
        end
      end
      
      module InstanceMethods
        def ignore_errors_on(properties)
          self.ignore_errors ||= []
          self.ignore_errors +=  Array(properties)
        end
        
        def valid?(force = nil)
          self.ignore_errors ||= []
          self.ignore_errors.map!(&:to_sym)
          
          super || self.errors.delete_if { |k,v| ignore_errors.include?(k.to_sym) }.size == 0
        end
        
        def versions(mounted_as)
          # if the taxonomy doesn't have this property, return blank hash
          return {} unless taxonomy.has_property?(mounted_as)
          # load the property
          property = taxonomy.properties[mounted_as.to_s]
          # map the versions into a hash
          (property.try(:image_versions) || []).inject({}) { |result,iv|
            result.merge(iv.name => iv.processes)
          }
        end
        
        private
        def generate_auto_incremented_id
          self.auto_incremented_id = (taxonomy.instances.order_by([[:auto_incremented_id, :desc]]).first.try(:auto_incremented_id) || 0) + 1 if new_record?
        end
        
        # process the rich text fields into HTML
        def process_rich_text
          taxonomy.physical_properties.where(:data_type => 'rich_text').each do |pp|
            if self.send(pp.name).present?
              write_attribute("#{pp.name}_rich_text_processed", RedCloth.new(self.send(pp.name)).to_html)
            end
          end
        end
        
        # process each virtual attribute
        def process_virtual_properties
          # loop through each attribute
          taxonomy.virtual_properties.each do |vp|
            # if this is a new instance
            # or the attribute can be set on update
            unless persisted? && vp.only_create?
              # get the value and set it
              write_attribute(vp.name, vp.value(self))
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