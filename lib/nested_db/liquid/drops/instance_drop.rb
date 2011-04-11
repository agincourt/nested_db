module NestedDb
  class InstanceDrop < ::Liquid::Drop
    def initialize(instance, taxonomy = nil)
      @instance = instance
    
      # loop through fields
      @instance.fields.keys.each { |k|
        self.class.send(:define_method, k.to_sym) do
          @instance.read_attribute(k)
        end
      }
    end
    
    def fields
      @instance.fields.keys
    end
    
    def taxonomy
      @taxonomy_drop ||= TaxonomyDrop.new(@instance.taxonomy)
    end
  end
end