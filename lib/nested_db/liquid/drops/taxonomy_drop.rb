module NestedDb
  class TaxonomyDrop < ::Liquid::Drop
    def initialize(taxonomy)
      @taxonomy = taxonomy
    end
  
    def name
      @taxonomy.name
    end
  
    def all
      @taxonomy.instances.limit(100).map { |i|
        InstanceDrop.new(i)
      }
    end
  
    def fields
      @taxonomy.instances.build.fields.keys
    end
  end
end