module NestedDb
  module Models
    module CallbackProcessing
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          before_create :run_taxonomy_before_create_callbacks
          after_create  :run_taxonomy_after_create_callbacks
          before_update :run_taxonomy_before_update_callbacks
          after_update  :run_taxonomy_after_update_callbacks
          before_save   :run_taxonomy_before_save_callbacks
          after_save    :run_taxonomy_after_save_callbacks
        end
      end
      
      module InstanceMethods
        private
        def run_taxonomy_before_create_callbacks
          run_taxonomy_callbacks :before_create
        end
        
        def run_taxonomy_after_create_callbacks
          run_taxonomy_callbacks :after_create
        end
        
        def run_taxonomy_before_update_callbacks
          run_taxonomy_callbacks :before_update
        end
        
        def run_taxonomy_after_update_callbacks
          run_taxonomy_callbacks :after_update
        end
        
        def run_taxonomy_before_save_callbacks
          run_taxonomy_callbacks :before_save
        end
        
        def run_taxonomy_after_save_callbacks
          run_taxonomy_callbacks :after_save
        end
        
        def run_taxonomy_callbacks(scope)
          taxonomy.callbacks.send("only_#{scope}").each { |c| c.run(self) } if taxonomy
        end
      end
    end
  end
end