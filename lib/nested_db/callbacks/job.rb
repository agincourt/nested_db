module NestedDb
  module Callbacks
    class Job < Struct.new(:instance_id, :callback_id)
      def perform
        callback.callback_class.run_immediately({
          :taxonomy => taxonomy,
          :instance => instance,
          :callback => callback
        })
      end
      
      def error(job, exception)
        HoptoadNotifier.notify(
          :error_class   => exception.class.name,
          :error_message => exception.message,
          :parameters    => { :instance_id => instance_id, :callback_id => callback_id }
        ) if defined?(HoptoadNotifier) && Rails.env.production?
      end

      private
      def instance
        return @instance if defined?(@instance)
        @instance = NestedDb::Instance.find(instance_id)
      end
      
      def taxonomy
        return @taxonomy if defined?(@taxonomy)
        @taxonomy = instance.taxonomy
      end
      
      def callback
        return @callback if defined?(@callback)
        @callback = taxonomy.instance_callbacks.find(callback_id)
      end
    end
  end
end