require 'rubygems'
require 'bundler/setup'
require 'nested_db'
require 'fileutils'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

LIQUID_MODELS = File.join(File.join(File.dirname(__FILE__), "..", "app", "models", "nested_db", "liquid"))
NESTED_DB_MODELS = File.join(File.join(File.dirname(__FILE__), "..", "app", "models", "nested_db"))
MODELS = File.join(File.join(File.dirname(__FILE__), "..", "app", "models"))
LIB = File.join(File.join(File.dirname(__FILE__), "..", "app", "lib"))
FACTORIES = File.join(File.dirname(__FILE__), "factories")
SUPPORT = File.join(File.dirname(__FILE__), "support")

require "rails"
require "mongoid"
require "mocha"
require "rspec"
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

[LIB, LIQUID_MODELS, NESTED_DB_MODELS, MODELS, SUPPORT, FACTORIES].each do |set|
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