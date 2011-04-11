module NestedDbRoutingHelper
  def taxonomy_relative_to_instance_path
    request.path.gsub(/\/instances$|\/instances\/.*?$/, '')
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