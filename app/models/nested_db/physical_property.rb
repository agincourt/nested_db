module NestedDb
  class PhysicalProperty < Property
    include DataTypes

    # fields
    field :unique,               :type => Boolean
    field :required,             :type => Boolean
    field :table_display,        :type => Boolean, :default => true
    field :form_display,         :type => Boolean, :default => true
    field :index,                :type => Integer, :default => 0, :required => true
    field :association_taxonomy, :type => String
    field :association_property, :type => String
    field :format,               :type => String

    # associations
    embedded_in :taxonomy,
      :inverse_of => :physical_properties
    embeds_many :image_versions,
      :inverse_of => :property,
      :class_name => "NestedDb::ImageVersion"
    accepts_nested_attributes_for :image_versions,
      :reject_if     => :all_blank,
      :allow_destroy => true

    # scopes
    scope :indexed,      where(:table_display => true)
    scope :form_display, where(:form_display => true)

    # validation
    validates_inclusion_of :data_type,
      :in => available_data_types
    validates_inclusion_of :format,
      :in          => %w(email),
      :allow_blank => true
    validate :validate_inclusion_of_association_taxonomy_in_taxonomies,
      :if => proc { |obj| ['belongs_to', 'has_many', 'has_and_belongs_to_many'].include?(obj.data_type) }
    validate :validate_association_property_in_association_taxonomy,
      :if => proc { |obj| obj.association_taxonomy.present? && 'belongs_to' == obj.data_type && 'has_and_belongs_to_many' == obj.data_type }
    validate :validate_association_property_in_association_taxonomy_belongs_to,
      :if => proc { |obj| obj.association_taxonomy.present? && 'has_many' == obj.data_type }

    # instance methods
    def field
      Mongoid::Field.new(name, :type => self.class.data_types[data_type.to_sym], :required => required?)
    end

    def foreign_taxonomy
      taxonomy.global_scope.where(:reference => association_taxonomy).first
    end

    def taxonomy_id
      foreign_taxonomy.id
    end

    def foreign_key
      association_property
    end

    private
    def validate_inclusion_of_association_taxonomy_in_taxonomies
      # load the available taxonomies
      choices = self.taxonomy.global_scope.all.map(&:reference)
      # check the taxonomy is available
      self.errors.add(:association_taxonomy, "must be selected") unless choices.include?(association_taxonomy)
    end

    def validate_association_property_in_association_taxonomy
      # load the properties of the taxonomy
      choices = self.taxonomy.global_scope.where(:reference => association_taxonomy).first.try(:physical_properties)
      # pull in names
      choices = (choices || []).map(&:name)
      # check property is in choices
      self.errors.add(:association_property, "must be chosen from: #{choices.join(', ')}") unless choices.include?(association_property)
    end

    def validate_association_property_in_association_taxonomy_belongs_to
      # load the remote taxonomy
      foreign_taxonomy = self.taxonomy.global_scope.where(:reference => association_taxonomy).first
      # load the belongs to properties of the taxonomy
      choices = foreign_taxonomy.physical_properties.select { |p| 'belongs_to' == p.data_type }
      # pull in names
      choices.map!(&:name)
      # check property is in choices
      self.errors.add(:association_property, "must be chosen from belongs_to: #{choices.join(', ')}") unless choices.include?(association_property)
    end

  end
end