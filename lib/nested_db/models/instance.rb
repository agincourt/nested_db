module NestedDb
  module Models
    module Instance
      def self.included(base)
        base.class_eval do
          # associations
          referenced_in :taxonomy, :inverse_of => :instances
          
          # validation
          validates_presence_of :taxonomy
          validate :validate_against_taxonomy, :if => proc { |obj| obj.taxonomy.present? }
        end
        base.send(:include, InstanceMethods)
      end
      
      module InstanceMethods
        # allows for readers when the attribute hasn't been
        # physically defined yet
        def method_missing(method, *args)
          if taxonomy && taxonomy.has_property?(method)
            read_attribute(method)
          else
            super(method, args)
          end
        end
        
        # allows for typecasting on the dynamic taxonomy fields
        def fields
          super().reverse_merge(taxonomy.try(:property_fields) || {})
        end
        
        private
        def validate_against_taxonomy
          taxonomy.validate_instance(self)
        end
      end
    end
  end
end