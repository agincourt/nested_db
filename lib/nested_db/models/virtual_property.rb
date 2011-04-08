require 'nested_db/models/property'

module NestedDb
  module Models
    module VirtualProperty
      def self.included(base)
        base.send(:include, NestedDb::Models::Property)
        base.class_eval do
          # fields
          field :format
          field :casing
  
          # validation
          validates_presence_of  :format
          validates_inclusion_of :data_type,
            :in => %w(string decimal integer)
          validates_inclusion_of :casing,
            :in => %w(downcase upcase titleize)
        end
        base.send(:include, InstanceMethods)
      end
      
      module InstanceMethods
        def field
          ::Mongoid::Field.new(name, :type => self.data_type.classify.constantize)
        end
      end
    end
  end
end