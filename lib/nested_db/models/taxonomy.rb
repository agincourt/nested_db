module NestedDb
  module Models
    module Taxonomy
      def self.included(base)
        base.send(:include, ::Mongoid::Document)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          cattr_accessor :scoped_to
          
          # fields
          field :name,      :required => true
          field :reference, :required => true
          field :scoped_type
          field :scoped_id
          
          # validation
          validates_format_of :reference,
            :with    => /^[\w\-]+$/,
            :message => 'may only contain lowercase letters, numbers, hyphons and underscores'
          validates_uniqueness_of :reference,
            :scope => [:scoped_type, :scoped_id]
          validates_presence_of :scoped_id,   :if => proc { |obj| obj.class.scoped? }
          validates_presence_of :scoped_type, :if => proc { |obj| obj.class.scoped? }
          
          # associations
          embeds_many     :physical_properties, :class_name => "NestedDb::PhysicalProperty"
          embeds_many     :virtual_properties, :class_name => "NestedDb::VirtualProperty"
          references_many :instances, :class_name => "NestedDb::Instance", :inverse_of => :taxonomy, :dependent => :destroy
          
          accepts_nested_attributes_for :physical_properties, :allow_destroy => true
          
          # callbacks
          before_validation :downcase_reference
        end
      end
      
      module ClassMethods
        def scoped?
          !!scoped_to
        end
        
        def scope_to(ref)
          self.scoped_to = ref
          
          define_method(ref) do
            scoped_object
          end
          
          define_method("#{ref}=") do |value|
            self.scoped_id   = value.id
            self.scoped_type = value.class.name
          end
        end
      end
      
      module InstanceMethods
        def scoped_object
          scoped_type.classify.constantize.find(scoped_id)
        end
        
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