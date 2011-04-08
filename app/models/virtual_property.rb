class NestedDb::VirtualProperty < NestedDb::Property
  # fields
  field :format
  field :casing
  
  # validation
  validates_presence_of  :format
  validates_inclusion_of :data_type,
    :in => %w(string decimal integer)
  validates_inclusion_of :casing,
    :in => %w(downcase upcase titleize)
  
  # public methods
  def field
    Mongoid::Field.new(name, :type => self.data_type.classify.constantize)
  end
end