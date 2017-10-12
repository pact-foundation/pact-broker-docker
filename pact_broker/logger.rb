require 'logger'

log_level = begin
  Kernel.const_get('Logger').const_get(ENV['PACT_BROKER_LOG_LEVEL'] || 'WARN')
rescue NameError
  $stderr.puts "Ignoring PACT_BROKER_LOG_LEVEL '#{ENV['PACT_BROKER_LOG_LEVEL']}' as it is invalid. Valid values are: DEBUG INFO WARN ERROR FATAL. Using WARN."
  Logger::WARN
end

$logger = ::Logger.new($stdout)
$logger.level = log_level
