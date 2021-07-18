require_relative "docker_configuration_2"
require 'logger'
require 'semantic_logger'

SemanticLogger.add_appender(io: $stdout, formatter: PactBroker.docker_configuration.log_format)
SemanticLogger.default_level = PactBroker.docker_configuration.log_level
$logger  = SemanticLogger['pact-broker']

PADRINO_LOGGER = {
  ENV.fetch('RACK_ENV').to_sym =>  { log_level: :error, stream: :stdout, format_datetime: '%Y-%m-%dT%H:%M:%S.000%:z' }
}
