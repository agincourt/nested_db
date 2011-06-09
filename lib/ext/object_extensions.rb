module NestedDb
  module ObjectExtensions
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def const_missing(name)
        if name =~ NestedDb::Instances.klass_regex
          NestedDb::Instances.create($1)
        else
          super(name)
        end
      end
    end
  end
end

Object.send(:include, NestedDb::ObjectExtensions)