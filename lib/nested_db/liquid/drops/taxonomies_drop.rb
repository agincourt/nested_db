module NestedDb
  class TaxonomiesDrop < Liquid::Drop
    def initialize(scope = nil)
      @scope = scope || Taxonomy.all
      # loop through each taxonomy
      @scope.each { |t|
        # generate a method for it
        self.class.send(:define_method, t.reference.to_sym) do
          TaxonomyDrop.new(t)
        end
      }
    end
  
    def count
      @scope.count
    end
  end
end