module NestedDb
  class Railtie < Rails::Railtie
    config.autoload_paths += %W( #{config.root}/app/liquid/drops )
  end
end