module AttributeFilter
  def call(input, attribute)
    input.send(attribute)
  end
end

Liquid::Template.register_filter(AttributeFilter)