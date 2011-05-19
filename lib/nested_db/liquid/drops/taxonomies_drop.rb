module NestedDb
  class TaxonomiesDrop < ::Liquid::Drop
    def initialize(scope = nil)
      @scope = scope || Taxonomy.all
    end
    
    def to_liquid
      @scope.inject({}) { |result,taxonomy|
        result.merge(taxonomy.reference => t)
      }
    end
  end
end