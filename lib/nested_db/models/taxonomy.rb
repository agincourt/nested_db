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
          embeds_many :physical_properties,
            :class_name => "NestedDb::PhysicalProperty",
            :inverse_of => :taxonomy
          embeds_many :virtual_properties,
            :class_name => "NestedDb::VirtualProperty",
            :inverse_of => :taxonomy
          has_many :instances,
            :class_name => "NestedDb::Instance",
            :inverse_of => :taxonomy,
            :dependent  => :destroy
          
          accepts_nested_attributes_for :physical_properties, :allow_destroy => true
          accepts_nested_attributes_for :virtual_properties,  :allow_destroy => true
          
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
            # only allow setting of scope on new records
            if new_record?
              self.scoped_id   = value.id
              self.scoped_type = value.class.name
            end
          end
        end
      end
      
      module InstanceMethods
        # returns a scope for finding taxonomies
        def global_scope
          respond_to?(:scoped_object) && scoped_object ? scoped_object.taxonomies : NestedDb::Taxonomy
        end
        
        def scoped_object
          scoped_type.classify.constantize.find(scoped_id) if self.class.scoped?
        end
        
        def has_property?(name)
          !!properties[name.to_s]
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
        
        def properties
          (
            Array(physical_properties) +
            Array(virtual_properties)
          ).inject({}) { |hash,p| hash.reverse_merge(p.name => p) }
        end
  
        private
        def downcase_reference
          self.reference.try(:downcase!)
        end
      end
    end
  end
end