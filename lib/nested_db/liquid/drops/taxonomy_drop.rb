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
      taxonomy.instances.limit(100)
    end
    
    def count
      taxonomy.instances.count
    end
  end
end