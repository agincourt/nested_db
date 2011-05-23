module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :instance
    attr_accessor :taxonomy_drop
    
    delegate :read_attribute, :attribute_present?, :attributes,
      :auto_incremented_id, :created_at,  :updated_at, :taxonomy,
      :persisted?, :new_record?,
      :to => "instance"
    
    def initialize(instance)
      self.instance = instance
    end
    
    def id
      auto_incremented_id
    end
    
    def errors
      instance.errors.map do |field,messages|
        Array(messages).map do |message|
          NestedDb::ErrorDrop.new(field,message)
        end
      end.flatten
    end
    
    def respond_to?(method)
      taxonomy.has_property?(method) || super
    end
    
    def method_missing(method)
      if taxonomy.has_property?(method)
        instance_value_for(method)
      else
        super
      end
    end
    
    def before_method(method)
      if taxonomy.has_property?(method)
        instance_value_for(method)
      else
        super
      end
    end
    
    private
    def instance_value_for(method)
      # load the property
      property = taxonomy.properties[method.to_s]
      # return nil if it wasn't found
      return nil unless property
      # typecast the value based on it's data type
      case property.data_type
      when 'rich_text'
        read_attribute("#{property.name}_rich_text_processed")
      when 'image', 'file'
        instance.send(property.name).try(:to_s)
      when 'password'
        nil
      else
        instance.send(property.name)
      end
    end
  end
end