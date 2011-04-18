module TaxonomyFieldsHelper
  def taxonomy_field(builder, property)
    case property.data_type
    when 'date'
      builder.date_select property.name, :order => [:day, :month, :year]
    when 'datetime'
      builder.datetime_select property.name, :order => [:day, :month, :year]
    when 'time'
      builder.time_select property.name, :order => [:hours, :minutes], :ignore_date => true
    when 'rich_text'
      builder.text_area property.name, :class => 'rich'
    when 'plain_text'
      builder.text_area property.name
    else
      builder.text_field property.name
    end
  end
end