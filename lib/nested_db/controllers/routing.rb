module NestedDb
  module Controllers
    module Routing
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          helper_method :taxonomy_relative_to_instance_path
          helper_method :taxonomy_relative_to_instance_url
          helper_method :instance_relative_to_taxonomy_path
          helper_method :instances_relative_to_taxonomy_path
        end
      end
    end
    
    module InstanceMethods
      def taxonomy_relative_to_instance_path
        request.path.gsub(/\/instances$|\/instances\/.*?$/, '')
      end
      
      def taxonomy_relative_to_instance_url
        request.url.gsub(/\/instances$|\/instances\/.*?$/, '')
      end
      
      def instance_relative_to_taxonomy_path(instance, action = nil)
        path = "#{instances_relative_to_taxonomy_path}/#{instance.id}"
        path += "/#{action}" if action
        path
      end
      
      def instances_relative_to_taxonomy_path(action = nil)
        path  = request.path.gsub(/(\/taxonomies\/\w{24}).*?$/, '\1/instances')
        path += "/#{action}" if action
        path
      end
    end
  end
end