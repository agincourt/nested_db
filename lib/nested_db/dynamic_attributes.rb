module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.send(:include, InstanceMethods)
      # setup our callbacks
      base.class_eval do
        
        after_build do
          Rails.logger.debug "NestedDb::DynamicAttributes after_build called"
          extend_based_on_taxonomy
        end
        
        after_initialize do
          extend_based_on_taxonomy if taxonomy
        end
        
      end
    end
    
    module InstanceMethods
      protected
      # dynamically adds fields for each of the taxonomy's properties
      def extend_based_on_taxonomy
        
        # load the metaclass
        metaclass = class << self; self; end
        # loop through each property
        taxonomy.properties.each do |name,property|
          case property.data_type
          # if it's a has_many property
          when 'has_many'
            metaclass.class_eval <<-END
              has_many :#{property.name},
                :class_name  => 'NestedDb::Instance',
                :foreign_key => :#{property.association_property}
              accepts_nested_attributes_for :#{property.name}
              Rails.logger.debug "Added has_many for #{property.name}"
            END
          # if it's a belongs_to property
          when 'belongs_to'
            metaclass.class_eval <<-END
              belongs_to :#{property.name},
                :class_name => 'NestedDb::Instance',
                :required   => #{property.required? ? 'true' : 'false'}
              Rails.logger.debug "Added belongs_to for #{property.name}"
            END
          # if it's a file property
          when 'file'
            # mount carrierwave
            metaclass.class_eval <<-END
              mount_uploader :#{property.name}, NestedDb::InstanceFileUploader
              Rails.logger.debug "Added uploader for #{property.name}"
            END
          # if it's a normal property (string etc)
          else
            metaclass.class_eval <<-END
              field :#{property.name},
                :type     => #{property.field_type.name},
                :required => #{property.required? ? 'true' : 'false'}
              Rails.logger.debug "Added field: #{property.name}, of type: #{property.field_type.name}"
            END
          end
        end # end loop through properties
        
      end
    end
  end
end