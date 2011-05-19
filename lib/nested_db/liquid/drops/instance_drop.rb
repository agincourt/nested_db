module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :instance
    attr_accessor :taxonomy_drop
    
    delegate :read_attribute,      :to => "instance"
    delegate :attribute_present?,  :to => "instance"
    delegate :attributes,          :to => "instance"
    delegate :auto_incremented_id, :to => "instance"
    delegate :created_at,          :to => "instance"
    delegate :updated_at,          :to => "instance"
    delegate :taxonomy,            :to => "instance"
    
    def initialize(instance)
      self.instance      = instance
    end
    
    def to_liquid
      # memoize
      return @properties if defined?(@properties)
      # load fields from taxonomy properties
      @properties = instance.taxonomy.properties.inject({}) do |result,arr|
        # load property from the array
        property = arr[1]
        
        # load value based on it's data type
        value = case property.data_type
        when 'rich_text'
          read_attribute("#{property.name}_rich_text_processed")
        when 'image', 'file'
          instance.send(property.name).try(:to_s)
        else
          instance.send(property.name)
        end
        
        result.merge(property.name => value)
      end
      
      # merge some other properties
      @properties.merge!({
        'taxonomy'   => taxonomy,
        'id'         => auto_incremented_id,
        'created_at' => created_at,
        'updated_at' => updated_at,
        'instance'   => instance
      })
      
      # return the properties
      @properties
    end
  end
end