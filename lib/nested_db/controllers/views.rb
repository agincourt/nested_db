module NestedDb
  module Controllers
    module Views
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def controller_path
          @@view_path_override || super
        end
        
        def default_views!
          @@view_path_override = name.gsub(/^.*\:\:/, '').gsub(/Controller$/, '')
        end
      end
    end
  end
end
      