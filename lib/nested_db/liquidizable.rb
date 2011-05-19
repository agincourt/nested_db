module Liquidizable
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      delegate :to_liquid, :to => "liquid_drop"
    end
  end
  
  module InstanceMethods
    def liquid_drop_class
      "#{self.class.name}Drop".constantize
    end
    
    def liquid_drop
      @liquid_drop ||= liquid_drop_class.new(self)
    end
  end
end