module NestedDb
  module Liquid
    class TaxonomiesDrop < ::Liquid::Drop
      attr_accessor :taxonomy_scope

      def initialize(scope = nil)
        self.taxonomy_scope = scope || Taxonomy.all
      end

      def to_liquid
        taxonomy_scope.inject({}) { |result,taxonomy|
          result.merge(taxonomy.reference => taxonomy)
        }
      end
    end
  end
end