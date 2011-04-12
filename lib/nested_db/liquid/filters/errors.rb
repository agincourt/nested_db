module ErrorFilter
  def die(input, status_code, status_message = nil)
    # if input is nil/false
    unless input
      raise StandardError, "Fail: #{status_code}, #{status_message}"
    end
    input
  end
end

Liquid::Template.register_filter(ErrorFilter)