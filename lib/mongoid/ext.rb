# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions
    module BuildCallbacks
      def build(attributes = {}, type = nil, &block)
        item = super
        item.run_callbacks(:build)
        item
      end
    end
  end
  
  module Relations #:nodoc:
    class Many < Proxy
      include Mongoid::Extensions::BuildCallbacks
    end
  end
  
  module Callbacks
    def self.included(base)
      super
      base.class_eval do
        define_model_callbacks :build
      end
    end
  end
end