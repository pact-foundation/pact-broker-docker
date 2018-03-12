require 'sequel'
require 'pact_broker'
require_relative 'logger'
require_relative 'basic_auth'
require_relative 'database_connection'
require_relative 'passenger_config'

app = PactBroker::App.new do | config |
  config.logger = $logger
  config.database_connection = create_database_connection(config.logger)
  config.database_connection.timezone = :utc
end

PactBroker.configuration.load_from_database!

basic_auth_username = ENV.fetch('PACT_BROKER_BASIC_AUTH_USERNAME','')
basic_auth_password = ENV.fetch('PACT_BROKER_BASIC_AUTH_PASSWORD', '')
use_basic_auth = basic_auth_username != '' && basic_auth_password != ''
allow_public_access_to_heartbeat = ENV.fetch('PACT_BROKER_PUBLIC_HEARTBEAT', '') == 'true'

if use_basic_auth
  app = BasicAuth.new(app, basic_auth_username, basic_auth_password, allow_public_access_to_heartbeat)
end

run app
