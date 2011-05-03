# encoding: utf-8
module Mongoid #:nodoc:
  module Extensions
    module BuildCallbacks
      # patches the build method to include running the after_build callback
      def build(attributes = {}, type = nil, &block)
        doc = super
        Rails.logger.debug "RUNNING BUILD CALLBACKS"
        doc.run_callbacks(:build) { doc }
        Rails.logger.debug "BUILD CALLBACKS COMPLETE"
        doc
      end
    end
  end
  
  module Callbacks
    def self.included(base)
      super
      base.class_eval do
        define_model_callbacks :build, :only => :after
      end
    end
  end
end

# patch the build method
Mongoid::Relations::Many.class_eval do
  include Mongoid::Extensions::BuildCallbacks
end