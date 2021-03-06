module NestedDb
  module Instances
    class << self
      cattr_accessor :defined_classes
      
      def regex
        /^:{2}?Instance([a-f0-9]{24})$/
      end

      def find_or_create(id)
        # laod our class name
        name = const_name(id)
        # if it's defined locally
        if defined_classes && defined_classes.has_key?(name)
          # return it
          defined_classes[name]
        # if Object has it
        elsif Object.const_defined?(name, false)
          # return it
          Object.const_get(name, false)
        # if nothing has it
        else
          # setup
          create(id)
        end
      end

      def create(id)
        klass = klass(id)
        Object.const_set(const_name(id), klass)
        self.defined_classes ||= {}
        self.defined_classes.merge!(const_name(id) => klass)
        klass.extend_from_taxonomy(taxonomy(id))
        klass
      end

      def delete(id)
        if self.defined_classes
          self.defined_classes.delete(const_name(id))
        end
        if Object.const_defined?(const_name(id), false)
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