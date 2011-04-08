module NestedDb
  module Models
    module Taxonomy
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          # fields
          field :name,      :required => true
          field :reference, :required => true
          
          # validation
          validates_format_of :reference,
            :with    => /^[\w\-]+$/,
            :message => 'may only contain lowercase letters, numbers, hyphons and underscores'
          
          # associations
          embeds_many     :physical_properties, :class_name => "NestedDb::PhysicalProperty"
          embeds_many     :virtual_properties, :class_name => "NestedDb::VirtualProperty"
          references_many :instances, :class_name => "NestedDb::Instance", :inverse_of => :taxonomy, :dependent => :destroy
          
          accepts_nested_attributes_for :physical_properties
          
          # callbacks
          before_validation :downcase_reference
        end
      end
      
      module InstanceMethods
        def has_property?(name)
          physical_properties.where(:name => name.to_s).count > 0
        end
  
        def property_fields
          (
            Array(physical_properties) +
            Array(virtual_properties)
          ).inject({}) { |hash,p| hash.merge(p.name => p.field) }
        end
  
        def validate_instance(instance)
          physical_properties.each { |p|
            p.validate_instance(instance)
          }
        end
  
        private
        def downcase_reference
          self.reference.try(:downcase!)
        end
      end
    end
  end
end