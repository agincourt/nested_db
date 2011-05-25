module NestedDb
  module Callbacks
    class Base
      attr_accessor :taxonomy, :instance, :callback
      
      def self.fields
        {}
      end
      
      def self.setup(options)
        new(options[:taxonomy], options[:instance], options[:callback])
      end
      
      def self.run(options)
        setup(options).queue
      end
      
      def self.run_immediately(options)
        setup(options).run
      end
      
      def initialize(taxonomy, instance, callback)
        self.taxonomy = taxonomy
        self.instance = instance
        self.callback = callback
      end
      
      def queue
        if defined?(Delayed::Job) && Rails.env.production?
          Delayed::Job.enqueue(NestedDb::Callbacks::Job.new(instance.id, callback.id))
        else
          run
        end
      end
      
      def run
        raise NotImplementedError
      end
    end
  end
end