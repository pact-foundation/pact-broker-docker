require "sequel"
require "pact_broker"
require "pact_broker/initializers/database_connection"
require_relative "logger"
require_relative "basic_auth"
require_relative "docker_configuration"
require_relative "pact_broker_resource_access_policy"

PactBroker.docker_configuration.log_configuration($logger)

app = PactBroker::App.new do | config |
  config.logger = $logger
  config.database_connection = PactBroker.create_database_connection(config.logger, config.database_configuration, config.database_connect_max_retries)
end

PactBroker.configuration.load_from_database!

basic_auth_username = ENV.fetch('PACT_BROKER_BASIC_AUTH_USERNAME','')
basic_auth_password = ENV.fetch('PACT_BROKER_BASIC_AUTH_PASSWORD', '')
basic_auth_read_only_username = ENV['PACT_BROKER_BASIC_AUTH_READ_ONLY_USERNAME']
basic_auth_read_only_password = ENV['PACT_BROKER_BASIC_AUTH_READ_ONLY_PASSWORD']
allow_public_read_access = ENV.fetch('PACT_BROKER_ALLOW_PUBLIC_READ', '') == 'true'
allow_public_access_to_heartbeat = ENV.fetch('PACT_BROKER_PUBLIC_HEARTBEAT', '') == 'true'
use_basic_auth = basic_auth_username != '' && basic_auth_password != ''

if use_basic_auth
  puts "INFO: Public read access is enabled" if allow_public_read_access
  policy = PactBrokerResourceAccessPolicy.build(allow_public_read_access, allow_public_access_to_heartbeat)
  use BasicAuth,
        [basic_auth_username, basic_auth_password],
        [basic_auth_read_only_username, basic_auth_read_only_password],
        policy
end

run app
