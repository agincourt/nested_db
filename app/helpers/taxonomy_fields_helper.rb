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
    when 'belongs_to'
      builder.select property.name, [['- Select one -', '']] + (taxonomy_scope.where(:reference => property.association_taxonomy).first.instances.excludes(:_id => builder.object.id).order_by(:"#{property.association_property}".asc) || []).map { |i|
        [i.send(property.association_property), i.id]
      }, :selected => builder.object.send(property.name).try(:id)
    when 'has_and_belongs_to_many'
      content_tag(:ul, :class => 'has_and_belongs_to_many') do
        (taxonomy_scope.where(:reference => property.association_taxonomy).first.instances.order_by(:"#{property.association_property}".asc) || []).map { |item|
          content_tag(:li,
            builder.check_box(:"#{property.name}_ids", { :id => "#{property.name}_ids_#{item.id}", :checked => (builder.object.send(:"#{property.name}_ids") || []).include?(item.id), :multiple => true }, item.id, nil) +
            builder.label(:"#{property.name}_ids_#{item.id}", item.send(property.association_property))
          )
        }.join("\n").html_safe
      end
    when 'image'
      arr = [
        builder.file_field(property.name, :class => 'file'),
        builder.hidden_field("#{property.name}_cache")
      ]
      if builder.object.persisted? && builder.object.send(property.name).present? && builder.object.send(property.name).to_s =~ /\.(png|gif|jpe?g)$/
        arr += [
          "<a href='#{builder.object.send(property.name)}' class='lightbox'>",
          image_tag( Instance.image_variation(builder.object.send(property.name), 'thumbnail'), :size => '95x70', :alt => 'Preview Image' ),
          "</a>"
        ]
      end
      arr.join.html_safe
    when 'file'
      [
        builder.file_field(property.name, :class => 'file'),
        builder.hidden_field("#{property.name}_cache")
      ].join.html_safe
    when 'password'
      builder.password_field property.name, :class => "text data_type_#{property.data_type}"
    else
      builder.text_field property.name, :class => "text data_type_#{property.data_type}"
    end
  end
end