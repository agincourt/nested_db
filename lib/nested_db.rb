module NestedDb
  class Railtie < Rails::Railtie
    ActiveSupport::Dependencies.autoload_paths += %W( #{root}/app/liquid/drops )
  end
end