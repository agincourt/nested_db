require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"
require "action_mailer/railtie"

module NestedDb
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.active_support.deprecation = :log
  end
end