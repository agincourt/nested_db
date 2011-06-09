module ImageDisplayFilter
  def variation(input, variation = nil)
    NestedDb::Instance.image_variation(input, variation)
  end
end

::Liquid::Template.register_filter(ImageDisplayFilter)