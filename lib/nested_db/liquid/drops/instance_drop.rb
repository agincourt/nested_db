module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :instance
    attr_accessor :taxonomy_drop
    
    def initialize(instance, taxonomy_drop = nil)
      self.instance      = instance
      self.taxonomy_drop = taxonomy_drop if taxonomy_drop
    
      # loop through fields
      self.instance.fields.keys.each { |k|
        self.class.send(:define_method, k.to_sym) do
          self.instance.read_attribute(k)
        end                                                                                                                                                                        
      }
    end
    
    def fields
      instance.fields.keys
    end
    
    def taxonomy
      self.taxonomy_drop ||= TaxonomyDrop.new(instance.taxonomy)
    end
  end
end