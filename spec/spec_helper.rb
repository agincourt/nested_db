require 'rubygems'
require 'bundler/setup'
require 'nested_db'
require 'fileutils'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
SUPPORT = File.join(File.dirname(__FILE__), "support")
$LOAD_PATH.unshift(MODELS)
$LOAD_PATH.unshift(SUPPORT)

require "rails"
require "mongoid"
require "mocha"
require "rspec"

LOGGER = Logger.new($stdout)

Mongoid.configure do |config|
  name = "nested_db_test"
  config.master = Mongo::Connection.new.db(name)
  config.logger = nil
end

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = true
end

Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }
Dir[ File.join(SUPPORT, "*.rb") ].each { |file| require File.basename(file) }

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
    NestedDb::Taxonomy.delete_all
    # delete all instances
    NestedDb::Instance.delete_all
  end
end