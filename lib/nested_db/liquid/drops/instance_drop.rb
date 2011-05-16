module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :instance
    attr_accessor :taxonomy_drop
    
    delegate :read_attribute,     :to => "instance"
    delegate :attribute_present?, :to => "instance"
    delegate :attributes,         :to => "instance"
    delegate :auto_increment_id,  :to => "instance"
    delegate :created_at,         :to => "instance"
    delegate :updated_at,         :to => "instance"
    
    def initialize(instance, taxonomy_drop = nil)
      self.instance      = instance
      self.taxonomy_drop = taxonomy_drop if taxonomy_drop
    end
    
    def to_liquid
      # memoize
      return @properties if defined?(@properties)
      # load fields from taxonomy properties
      @properties = taxonomy.properties.inject({}) do |result,property|
        value = case property.data_type
        when 'rich_text'
          read_attribute("#{property.name}_rich_text_processed")
        when 'belongs_to'
          InstanceDrop.new(read_attribute(property.name))
        when 'has_many'
          read_attribute(property.name).map { |i| InstanceDrop.new(i) }
        else
          read_attribute(property.name)
        end
        
        result.merge(property.name => value)
      end
      
      # merge some other properties
      @properties.merge!({
        :taxonomy   => taxonomy,
        :id         => auto_increment_id,
        :created_at => created_at,
        :updated_at => updated_at
      })
      
      # return the properties
      @properties
    end
    
    def taxonomy
      self.taxonomy_drop ||= TaxonomyDrop.new(instance.taxonomy)
    end
  end
end