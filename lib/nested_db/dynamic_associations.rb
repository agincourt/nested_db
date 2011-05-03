module NestedDb
  module DynamicAssociations
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do
        attr_accessor    :dynamic_associations
        after_initialize :setup_dynamic_associations
      end
    end
    
    module InstanceMethods
      # allows for typecasting on the dynamic taxonomy fields
      def fields
        super.merge(dynamic_associations.inject({}) { |hash,name,metadata|
          if metadata.relation.stores_foreign_key?
            hash.merge!(name => Mongoid::Field.new(name, :identity => true, :metadata => metadata, :default => metadata.foreign_key_default, :required => property.required?))
          end
          hash
        })
      end
      
      # overrides relations method to include our dynamic definitions
      def relations
        self.class.relations.merge(dynamic_associations)
      end
      
      # intercept read_attribute and check for associations
      #def read_attribute(method)
      #  if dynamic_associations.has_key?(method.to_s)
      #    dynamic_associations[method.to_s]
      #  else
      #    super(method)
      #  end
      #rescue Mongoid::Errors::DocumentNotFound => e
      #  Rails.logger.debug "#{e.class.name.to_s} => #{e.message}"
      #  nil
      #end
      
      private
      def setup_dynamic_associations
        # setup a hash to store the associations
        self.dynamic_associations ||= {}
        # loop through the taxonomy's has_many associations
        taxonomy.physical_properties.where(:data_type => 'has_many').each do |property|
          self.dynamic_associations.merge!(          
            property.name => Mongoid::Relations::Metadata.new(
              :relation           => Referenced::Many,
              :inverse_class_name => self.class.name,
              :name               => property.name,
              :property           => property
            )
          )
        end
        # loop through the taxonomy's belongs_to associations
        taxonomy.physical_properties.where(:data_type => 'belongs_to').each do |property|
          self.dynamic_associations.merge!(          
            property.name => Mongoid::Relations::Metadata.new(
              :relation           => Referenced::In,
              :inverse_class_name => self.class.name,
              :name               => property.name
            )
          )
        end
      end
    end
  end
end