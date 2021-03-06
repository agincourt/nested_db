module NestedDb
  module Controllers
    module Scoping
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          helper_method :taxonomy_scope
        end
      end
    end

    module InstanceMethods
      protected
      def taxonomy_scope
        raise StandardError, "No taxonomy_scope method written for the scoping" if Taxonomy.scoped?
        Taxonomy
      end

      def scope_parent
        raise StandardError, "No scope_parent method written for the scoping"
      end
    end
  end
end