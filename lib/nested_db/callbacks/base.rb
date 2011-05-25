module NestedDb
  module Callbacks
    class Base
      class << self
        def reference(reference = nil)
          @@reference = reference if reference
          @@reference
        end
        
        def configure(&proc)
          @@configure = proc if proc
          @@configure
        end
        
        def apply_to(klass)
          klass.class_eval(&configure) if configure
        end
        
        def setup(options)
          new(options[:taxonomy], options[:instance], options[:callback])
        end
      
        def run(options)
          setup(options).queue
        end
      
        def run_immediately(options)
          setup(options).run
        end
      end
      
      attr_accessor :taxonomy, :instance, :callback
      
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