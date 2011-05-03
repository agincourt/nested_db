module NestedDb
  module DynamicAttributes
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        after_initialize :extend_based_on_taxonomy
      end
    end
    
    module InstanceMethods
      protected
      def extend_based_on_taxonomy
        metaclass = class << self; self; end
        
        metaclass.class_eval do
          taxonomy.properties.each do |name,property|
            case property.data_type
            when 'has_many'
              has_many property.name,
                :class_name  => 'NestedDb::Instance',
                :foreign_key => property.association_property
            when 'belongs_to'
              belongs_to property.name,
                :class_name => 'NestedDb::Instance',
                :required   => property.required?
            when 'file'
              mount_uploader property.name, NestedDb::InstanceFileUploader
            else
              field property.name,
                :type     => property.field_type,
                :required => property.required?
            end
          end
        end
      end
    end
  end
end