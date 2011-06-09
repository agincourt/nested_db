module AttributeFilter
  def call(input, attribute)
    input.try(attribute.to_sym)
  end
end

::Liquid::Template.register_filter(AttributeFilter)