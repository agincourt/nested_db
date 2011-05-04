module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
      # setup our callbacks
      base.class_eval do
        
        attr_accessor :extended_from_taxonomy
        
        after_build do
          extend_based_on_taxonomy
        end
        
        after_initialize do
          extend_based_on_taxonomy if taxonomy
        end
        
      end
    end
    
    module InstanceMethods
      def metaclass
        # memoize
        return @metaclass if defined?(@metaclass)
        # load the meta class
        @metaclass = class << self; self; end
        # define a name on it
        @metaclass.class_eval %Q{
          def self.name
            'NestedDb::Instance'
          end
        }
        # return it
        @metaclass
      end
      
      def uploaders
        metaclass.uploaders
      end
      
      def uploader_options
        metaclass.uploader_options
      end
      
      protected
      # dynamically adds fields for each of the taxonomy's properties
      def extend_based_on_taxonomy
        # don't re-extend if this method has already been run
        return if extended_from_taxonomy
        # loop through each property
        taxonomy.properties.each do |name,property|
          case property.data_type
          # if it's a has_many property
          when 'has_many'
            metaclass.class_eval <<-END
              has_many :#{property.name},
                :class_name         => 'NestedDb::Instance',
                :inverse_class_name => 'NestedDb::Instance',
                :foreign_key        => '#{property.association_property}_id'
              accepts_nested_attributes_for :#{property.name}
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
        end # end loop through properties
        
        # mark as extended
        self.extended_from_taxonomy = true
      end
    end
  end
end