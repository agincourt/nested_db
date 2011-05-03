# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    class Many < Proxy
      include Mongoid::Extensions::BuildCallbacks
    end
  end
  
  module Extensions
    module BuildCallbacks
      def build(attributes = {}, type = nil, &block)
        item = super
        item.run_callbacks(:build)
        item
      end
    end
  end
end