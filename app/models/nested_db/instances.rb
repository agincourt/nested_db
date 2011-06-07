module NestedDb
  class Instances
    class << self
      def find_or_create(taxonomy)
        if const_defined?(klass_name(taxonomy))
          const_get(klass_name(taxonomy))
        else
          const_set(klass_name(taxonomy), klass(taxonomy))
        end
      end

      def delete(taxonomy)
        remove_const(klass_name(taxonomy)) if const_defined?(klass_name(taxonomy))
      end

      def klass_name(taxonomy)
        "Instance#{taxonomy.id.to_s}"
      end

      def klass(taxonomy)
        klass = Class.new(::Instance)
        klass.extend_from_taxonomy(taxonomy)
        klass
      end
    end
  end
end