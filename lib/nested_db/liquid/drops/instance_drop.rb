module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :instance
    attr_accessor :taxonomy_drop
    
    delegate :read_attribute,     :to => "instance"
    delegate :attribute_present?, :to => "instance"
    delegate :attributes,         :to => "instance"
    
    def initialize(instance, taxonomy_drop = nil)
      self.instance      = instance
      self.taxonomy_drop = taxonomy_drop if taxonomy_drop
    
      # loop through fields
      attributes.each do |k|
        self.class.send(:define_method, k.to_sym) do
          attribute_present?("#{k.to_s}_rich_text_processed") ? read_attribute("#{k.to_s}_rich_text_processed") : read_attribute(k)
        end                                                                                                                                                                        
      end
    end
    
    def fields
      instance.attributes.keys
    end
    
    def taxonomy
      self.taxonomy_drop ||= TaxonomyDrop.new(instance.taxonomy)
    end
  end
end