module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        after_build :extend_based_on_taxonomy
      end
    end
    
    module InstanceMethods
      protected
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
            END
          # if it's a belongs_to property
          when 'belongs_to'
            metaclass.class_eval <<-END
              belongs_to :#{property.name},
                :class_name => 'NestedDb::Instance',
                :required   => #{property.required? ? 'true' : 'false'}
            END
          # if it's a file property
          when 'file'
            # mount carrierwave
            metaclass.class_eval <<-END
              mount_uploader :#{property.name}, NestedDb::InstanceFileUploader
            END
          # if it's a normal property (string etc)
          else
            metaclass.class_eval <<-END
              field :#{property.name},
                :type     => #{property.field_type.name},
                :required => #{property.required? ? 'true' : 'false'}
            END
          end
          Rails.logger.debug "Appending field name: #{property.name}"
        end
      end
    end
  end
end