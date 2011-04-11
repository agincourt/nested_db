module FindOneFilter
  def find_one_by(taxonomy_drop, attribute, value)
    # ensure the taxonomy has the property
    return nil unless taxonomy_drop.taxonomy.has_property?(attribute)
    # try to load a result
    result = taxonomy_drop.taxonomy.instances.where({ attribute => value }).find(:first)
    # if we have a result transform into drop
    InstanceDrop.new(result, taxonomy_drop) if result
  end
end

module FindAllFilter
  def find_all_by(taxonomy_drop, attribute, value, limit = 100)
    # ensure the taxonomy has the property
    return nil unless taxonomy_drop.taxonomy.has_property?(attribute)
    # try to load some results
    taxonomy_drop.taxonomy.instances.where({ attribute => value }).limit([100, limit].min).map { |result|
      # transform each result into drop
      InstanceDrop.new(result, taxonomy_drop)
    }
  end
end

Liquid::Template.register_filter(FindOneFilter)
Liquid::Template.register_filter(FindAllFilter)