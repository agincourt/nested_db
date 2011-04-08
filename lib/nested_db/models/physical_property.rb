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
          field :required,      :type => Boolean
          field :table_display, :type => Boolean, :default => true
          field :index,         :type => Integer, :default => 0, :required => true
          
          # scopes
          scope :indexed, where(:table_display => true)
          
          # validation
          validates_inclusion_of :data_type,
            :in => available_data_types
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