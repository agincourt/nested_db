module NestedDb
  module Instances
    class << self
      def klass_regex
        /^:{2}?Instance([a-f0-9]{24})$/
      end

      def find_or_create(id)
        if Object.const_defined?(const_name(id))
          Object.const_get(const_name(id))
        else
          create(id)
        end
      end

      def create(id)
        puts "Defining Instance#{id.to_s}"
        klass = klass(id)
        puts "Setting Instance#{id.to_s}"
        Object.const_set(const_name(id), klass)
        klass.extend_from_taxonomy(taxonomy(id))
        puts "Returning Instance#{id.to_s}"
        klass
      end

      def delete(id)
        if Object.const_defined?(const_name(id))
          Object.send(:remove_const, const_name(id))
        end
      end

      def klass_name(id)
        const_name(id)
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