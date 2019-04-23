require 'sequel'
require 'pact_broker'
require_relative 'logger'
require_relative 'basic_auth'
require_relative 'database_connection'
require_relative 'docker_configuration'

dc = PactBroker::DockerConfiguration.new(ENV, PactBroker::Configuration.default_configuration)
dc.pact_broker_environment_variables.each{ |key, value| $logger.info "#{key}=#{value}"}

app = PactBroker::App.new do | config |
  config.logger = $logger
  config.database_connection = create_database_connection(config.logger)
  config.database_connection.timezone = :utc
  config.webhook_host_whitelist = dc.webhook_host_whitelist
  config.webhook_http_method_whitelist = dc.webhook_http_method_whitelist
  config.webhook_scheme_whitelist = dc.webhook_scheme_whitelist
  config.base_equality_only_on_content_that_affects_verification_results = dc.base_equality_only_on_content_that_affects_verification_results
  config.order_versions_by_date = dc.order_versions_by_date
  config.disable_ssl_verification = dc.disable_ssl_verification
end

PactBroker.configuration.load_from_database!

PactBroker::Configuration::SAVABLE_SETTING_NAMES.each do | setting |
  $logger.info "PactBroker.configuration.#{setting}=#{PactBroker.configuration.send(setting).inspect}"
end

basic_auth_username = ENV.fetch('PACT_BROKER_BASIC_AUTH_USERNAME','')
basic_auth_password = ENV.fetch('PACT_BROKER_BASIC_AUTH_PASSWORD', '')
basic_auth_read_only_username = ENV.fetch('PACT_BROKER_BASIC_AUTH_READ_ONLY_USERNAME','')
basic_auth_read_only_password = ENV.fetch('PACT_BROKER_BASIC_AUTH_READ_ONLY_PASSWORD', '')
use_basic_auth = basic_auth_username != '' && basic_auth_password != ''
allow_public_access_to_heartbeat = ENV.fetch('PACT_BROKER_PUBLIC_HEARTBEAT', '') == 'true'

if use_basic_auth
  use BasicAuth,
        basic_auth_username,
        basic_auth_password,
        basic_auth_read_only_username,
        basic_auth_read_only_password,
        allow_public_access_to_heartbeat
end

run app
