require 'logger'
require 'sequel'
require 'pact_broker'
require_relative 'basic_auth'
require_relative 'database_connection'
require_relative 'passenger_config'

app = PactBroker::App.new do | config |
  config.logger = ::Logger.new($stdout)
  config.logger.level = Logger::WARN
  config.database_connection = create_database_connection(config.logger)
  config.database_connection.timezone = :utc
end

basic_auth_username = ENV.fetch('PACT_BROKER_BASIC_AUTH_USERNAME','')
basic_auth_password = ENV.fetch('PACT_BROKER_BASIC_AUTH_PASSWORD', '')
use_basic_auth = basic_auth_username != '' && basic_auth_password != ''

if use_basic_auth
  app = BasicAuth.new(app, basic_auth_username, basic_auth_password)
end

run app
