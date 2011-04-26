require 'nested_db/data_types'
require 'nested_db/models/property'

module NestedDb
  module Models
    module PhysicalProperty
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.send(:include, NestedDb::DataTypes)
        base.send(:include, NestedDb::Models::Property)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          # fields
          field :required,             :type => Boolean
          field :table_display,        :type => Boolean, :default => true
          field :index,                :type => Integer, :default => 0, :required => true
          field :association_taxonomy, :type => String
          
          # scopes
          scope :indexed, where(:table_display => true)
          
          # validation
          validates_inclusion_of :data_type,
            :in => available_data_types
          validates_inclusion_of :association_taxonomy,
            :in => proc { |obj|
              obj.taxonomy.respond_to?(:scoped_object) &&
              obj.taxonomy.scoped_object ?
              obj.taxonomy.scoped_object.taxonomies.map(&:reference) :
              NestedDb::Taxonomy.all.map(&:reference)
            },
            :if => proc { |obj| 'belongs_to' == obj.data_type }
        end
      end
      
      module InstanceMethods
        def validate_instance(instance)
          value = instance.send(name)
          
          if required? && value.blank?
            instance.errors.add(name, "cannot be blank")
          end
        end
        
        def field
          Mongoid::Field.new(name, :type => self.class.data_types[data_type.to_sym], :required => required?)
        end
      end
    end
  end
end