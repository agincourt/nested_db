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
      builder.text_area property.name, :class => 'plain'
    when 'file'
      if builder.object.new_record?
        builder.file_field property.name, :class => 'file'
      else
        [
          builder.file_field(property.name, :class => 'file'),
          image_tag( NestedDb::Instance.image_variation(builder.object.send(property.name), 'thumbnail'), :size => '95x70', :alt => 'Preview Image' )
        ].join.html_safe
      end
    else
      builder.text_field property.name, :class => "text data_type_#{property.data_type}"
    end
  end
end