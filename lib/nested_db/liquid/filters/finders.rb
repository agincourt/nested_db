module FindOneFilter
  def find_one_by(input, attribute, value)
    # ensure the taxonomy has the property
    return false unless input.taxonomy.has_property?(attribute)
    # try to load a result
    result = input.taxonomy.instances.where({ attribute => value }).find(:first)
    # if we have a result transform into drop
    return NestedDb::InstanceDrop.new(result, input) if result
    # if no result
    return false
  end
end

module FindAllFilter
  def find_all_by(input, attribute, value, limit = 100)
    # ensure the taxonomy has the property
    return false unless input.taxonomy.has_property?(attribute)
    # try to load some results
    input.taxonomy.instances.where({ attribute => value }).limit([100, limit.to_i].min).map { |result|
      # transform each result into drop
      NestedDb::InstanceDrop.new(result, input)
    }
  end
end

Liquid::Template.register_filter(FindOneFilter)
Liquid::Template.register_filter(FindAllFilter)