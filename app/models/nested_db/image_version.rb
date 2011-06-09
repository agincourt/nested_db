module NestedDb
  class ImageVersion
    include Mongoid::Document

    # associations
    embedded_in :property,
      :inverse_of => :image_versions,
      :class_name => "NestedDb::PhysicalProperty"

    # fields
    field :name,   :type => String
    field :width,  :type => Integer
    field :height, :type => Integer
    field :operation, :type => String

    # validation
    validates_numericality_of :width,
      :greater_than          => 0,
      :less_than_or_equal_to => 1000,
      :only_integer          => true
    validates_numericality_of :height,
      :greater_than          => 0,
      :less_than_or_equal_to => 1000,
      :only_integer          => true
    validates_inclusion_of :operation, :in => %w(resize_to_fit resize_to_fill)

    def processes
      [
        [ 'resize_to_fit' == operation ? :resize_to_limit : operation.to_sym, [width,height] ]
      ]
    end
  end
end