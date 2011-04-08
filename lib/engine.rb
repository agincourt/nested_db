require 'nested_db'
require 'rails'
require 'action_controller'
require 'application_helper'

module NestedDb
  class Engine < ::Rails::Engine
    config.mount_at = '/'
  end
end