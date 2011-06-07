module NestedDb
  class Instances
    class << self
      def klass_regex
        /^NestedDb::Instances::Instance[a-f0-9]{24}$/
      end

      def find_or_create(id)
        if const_defined?(const_name(id))
          const_get(const_name(id))
        else
          klass = klass(id)
          const_set(const_name(id), klass)
          klass.extend_from_taxonomy(taxonomy(id))
          klass.build_associations
          klass
        end
      end

      def delete(id)
        remove_const(const_name(id)) if const_defined?(const_name(id))
      end

      def klass_name(id)
        "NestedDb::Instances::#{const_name(id)}"
      end

      private
      def taxonomy(id)
        ::Taxonomy.find(id)
      end

      def const_name(id)
        "Instance#{id.to_s}"
      end

      def klass(id)
        Class.new(::Instance)
      end
    end
  end
end