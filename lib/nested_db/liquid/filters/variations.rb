module ImageDisplayFilter
  def variation(input, variation = nil)
    input.gsub(/^(.*)\/(.*?)$/, "\\1/variation_\\2") if variation
    input
  end
end

Liquid::Template.register_filter(ImageDisplayFilter)