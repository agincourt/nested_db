require 'nested_db'
require 'rails'

module NestedDb
  class Engine < ::Rails::Engine
    #config.mount_at = '/'
    #initializer 'nested_db.helper' do |app|
    #  ActionView::Base.send :include, TaxonomyFieldsHelper
    #end
  end
end