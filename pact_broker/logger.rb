require 'logger'

log_level = begin
  Kernel.const_get('Logger').const_get(ENV['PACT_BROKER_LOG_LEVEL'] || 'WARN')
rescue NameError
  $stderr.puts "Ignoring PACT_BROKER_LOG_LEVEL '#{ENV['PACT_BROKER_LOG_LEVEL']}' as it is invalid. Valid values are: DEBUG INFO WARN ERROR FATAL. Using WARN."
  Logger::WARN
end

SemanticLogger.add_appender(io: $stdout)
SemanticLogger.default_level = log_level
$logger  = SemanticLogger['root']

PADRINO_LOGGER = {
  ENV.fetch('RACK_ENV').to_sym =>  { log_level: :error, stream: :stdout, format_datetime: '%Y-%m-%dT%H:%M:%S.000%:z' }
}
