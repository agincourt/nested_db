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
        NestedDb::Taxonomy
      end
    end
  end
end