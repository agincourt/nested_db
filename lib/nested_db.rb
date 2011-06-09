require 'mongoid'
require 'engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
require 'carrierwave'
require 'ext/carrierwave'
require 'nested_db/property'
require 'nested_db/data_types'
require 'nested_db/controllers'
require 'nested_db/encryption'
require 'nested_db/dynamic_attributes'
require 'nested_db/models'
require 'nested_db/routes' if defined?(ActionDispatch)
require 'nested_db/liquidizable' unless defined?(Liquidizable)
require 'nested_db/liquid'
require 'nested_db/callbacks'