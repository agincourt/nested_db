class InstancesController < ApplicationController
  include NestedDb::InstancesController

  # You can override the following methods to adjust behaviour:
  # def not_found; end
  # => what happens when either taxonomy/instance fail to be found
  # def loading_taxonomy_failed; end
  # => what happens when taxonomy cannot be found
  # def loading_instance_failed; end
  # => what happens when instance cannot be found
end