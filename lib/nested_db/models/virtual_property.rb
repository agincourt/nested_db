require 'nested_db/models/property'

module NestedDb
  module Models
    module VirtualProperty
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.send(:include, NestedDb::Models::Property)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          extend ClassMethods
          
          # fields
          field :format
          field :casing
          
          # associations
          embedded_in :taxonomy,
            :inverse_of => :virtual_properties,
            :class_name => "NestedDb::Taxonomy"
  
          # validation
          validates_presence_of  :format
          validates_inclusion_of :data_type,
            :in => %w(string decimal integer)
          validates_inclusion_of :casing,
            :in => %w(downcase upcase titleize permalink),
            :allow_blank => true
        end
      end
      
      module ClassMethods
        def data_types
          {
            :string  => String,
            :integer => Integer,
            :decimal => Float
          }
        end
      end
      
      module InstanceMethods
        def field_type
          self.class.data_types[data_type.to_sym] || String
        end
        
        def field
          ::Mongoid::Field.new(name, :type => self.data_type.classify.constantize)
        end
      end
    end
  end
end