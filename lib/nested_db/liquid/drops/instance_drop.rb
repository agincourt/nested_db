module NestedDb
  class InstanceDrop < ::Liquid::Drop
    attr_accessor :taxonomy_instance
    attr_accessor :taxonomy_drop
    
    def initialize(instance, taxonomy_drop = nil)
      self.taxonomy_instance = instance
      self.taxonomy_drop     = taxonomy_drop if taxonomy_drop
    
      # loop through fields
      taxonomy_instance.fields.keys.each { |k|
        self.class.send(:define_method, k.to_sym) do
          #taxonomy_instance.read_attribute(k)
          "TEST"
        end                                                                                                                                                                        
      }
    end
    
    def fields
      taxonomy_instance.fields.keys
    end
    
    def taxonomy
      self.taxonomy_drop ||= TaxonomyDrop.new(taxonomy_instance.taxonomy)
    end
  end
end