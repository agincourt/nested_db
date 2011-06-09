require 'rubygems'
require 'bundler/setup'
require 'fileutils'
require "action_controller/railtie"
require "action_mailer/railtie"
require 'nested_db'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

LIQUID_MODELS = File.join(File.join(File.dirname(__FILE__), "..", "app", "models", "nested_db", "liquid"))
NESTED_DB_MODELS = File.join(File.join(File.dirname(__FILE__), "..", "app", "models", "nested_db"))
MODELS = File.join(File.join(File.dirname(__FILE__), "..", "app", "models"))
NESTED_DB_CONTROLLERS = File.join(File.join(File.dirname(__FILE__), "..", "app", "controllers", "nested_db"))
CONTROLLERS = File.join(File.join(File.dirname(__FILE__), "..", "app", "controllers"))
LIB = File.join(File.join(File.dirname(__FILE__), "..", "app", "lib"))
FACTORIES = File.join(File.dirname(__FILE__), "factories")
SUPPORT = File.join(File.dirname(__FILE__), "support")

#require File.join(File.join(File.dirname(__FILE__), "support", "environment.rb"))
require "mongoid"
require "mocha"
require "rspec/rails"
require "factory_girl"
require "factory_girl_rails"

LOGGER = Logger.new($stdout)

Mongoid.configure do |config|
  name = "nested_db_test"
  config.master = Mongo::Connection.new.db(name)
  config.logger = nil
end

CarrierWave.configure do |config|
  config.root    = 'test'
  config.storage = :file
  config.enable_processing = true
end

[
  LIB, NESTED_DB_MODELS, NESTED_DB_CONTROLLERS, LIQUID_MODELS,
  MODELS, CONTROLLERS, FACTORIES #, SUPPORT
].each do |set|
  $LOAD_PATH.unshift(set)
  Dir[ File.join(set, "*.rb") ].sort.each { |file| require File.basename(file) }
end

Rspec.configure do |config|
  config.mock_with(:mocha)
  config.after(:suite) do
    Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)
    FileUtils.rm_rf File.join(File.dirname(__FILE__), '..', 'test')
    FileUtils.rm_rf File.join(File.dirname(__FILE__), '..', 'uploads')
    FileUtils.rm_rf File.join(File.dirname(__FILE__), '..', 'system')
  end
  config.before(:suite) do
    # delete all taxonomies
    Taxonomy.delete_all
    NestedDb::Taxonomy.delete_all
    # delete all instances
    Instance.delete_all
    NestedDb::Instance.delete_all
  end
end