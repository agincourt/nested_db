module TaxonomyFieldsHelper
  def taxonomy_field(builder, property)
    case property.data_type
    when 'date'
      builder.date_select property.name
    when 'text'
      builder.text_area property.name
    else
      builder.text_field property.name
    end
  end
end