module NestedDb
  class Taxonomy
    include Mongoid::Document
    include Mongoid::Timestamps
    include Liquidizable

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
    embeds_many :instance_callbacks,
      :class_name => "NestedDb::InstanceCallback",
      :inverse_of => :taxonomy

    accepts_nested_attributes_for :physical_properties, :allow_destroy => true, :reject_if => :all_blank
    accepts_nested_attributes_for :virtual_properties,  :allow_destroy => true, :reject_if => :all_blank
    accepts_nested_attributes_for :instance_callbacks,  :allow_destroy => true, :reject_if => :all_blank

    # callbacks
    before_validation :downcase_reference
    after_update      :remove_instance_class
    after_destroy     :remove_instance_class

    # class methods
    class << self
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

    # instance methods
    def instances
      NestedDb::Proxy.from(self).to(:instances)
    end

    # returns a scope for finding taxonomies
    def global_scope
      respond_to?(:scoped_object) && scoped_object ? scoped_object.taxonomies : Taxonomy
    end

    # returns a class which will be used to
    # represent individual taxonomies in liquid
    def liquid_drop_class
      NestedDb::Liquid::TaxonomyDrop
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

    def properties
      (
        Array(physical_properties) +
        Array(virtual_properties)
      ).inject({}) { |hash,p| hash.reverse_merge(p.name => p) }
    end

    def instance_class
      if Instances.const_defined?("Instance#{id.to_s}")
        Instances.const_get("Instance#{id.to_s}")
      else
        Instances.const_set("Instance#{id.to_s}", new_instance_class)
      end
    end

    private
    def downcase_reference
      self.reference.try(:downcase!)
    end

    def new_instance_class
      klass = Class.new(::Instance)
      klass.extend_from_taxonomy(self)
      klass
    end

    def remove_instance_class
      if Instances.const_defined?("Instance#{id.to_s}")
        Instances.remove_const("Instance#{id.to_s}")
      end
    end
  end
end