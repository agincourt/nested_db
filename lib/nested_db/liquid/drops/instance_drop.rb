module NestedDb
  class InstanceDrop < ::Liquid::Drop
    def initialize(instance)
      @instance = instance
    
      # loop through fields
      @instance.fields.each { |k,v|
        self.class.send(:define_method, k.to_sym) do
          @instance.read_attribute(k)
        end
      }
    end
  end
end