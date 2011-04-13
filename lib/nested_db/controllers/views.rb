module NestedDb
  module Controllers
    module Views
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def controller_path
          defined?(@@view_path_override) ? @@view_path_override : super
        end
        
        def default_views!
          @@view_path_override = default_view_path
        end
        
        private
        def default_view_path
          name.gsub(/^.*\:\:/, '').gsub(/Controller$/, '')
        end
      end
    end
  end
end
      