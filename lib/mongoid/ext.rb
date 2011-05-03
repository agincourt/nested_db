# encoding: utf-8
module Mongoid #:nodoc:
  module Relations #:nodoc:
    class Many < Proxy
      # simply processes a callback
      def build_with_callback
        run_callbacks(:build) { self }
      end
      
      # call build_callback after build
      alias_method_chain :build, :callback
      
      define_model_callbacks :build, :only => :after
    end
  end
end