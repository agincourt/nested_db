module NestedDb
  class TaxonomyDrop < ::Liquid::Drop
    attr_accessor :taxonomy
    
    def initialize(taxonomy)
      self.taxonomy = taxonomy
    end
  
    def name
      taxonomy.name
    end
  
    def all
      taxonomy.instances.limit(100).map { |i|
        InstanceDrop.new(i, self)
      }
    end
    
    def count
      taxonomy.instances.count
    end
  
    def fields
      taxonomy.instances.build.fields.keys
    end
  end
end