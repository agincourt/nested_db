module NestedDb
  module Controllers
    module Scoping
      def self.included(base)
        base.send(:include, InstanceMethods)
      end
    end
    
    module InstanceMethods
      protected
      def taxonomy_scope
        raise StandardError, "No taxonomy_scope method written for the scoping" if NestedDb::Taxonomy.scoped?
        NestedDb::Taxonomy
      end
    end
  end
end