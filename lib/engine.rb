require 'nested_db'
require 'rails'

module NestedDb
  class Engine < ::Rails::Engine
    config.mount_at = '/'
  end
end