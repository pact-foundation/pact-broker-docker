require_relative "../docker_configuration"

plugin 'metrics'
puma_metrics_port = ENV['PACT_BROKER_PUMA_METRICS_PORT'] || (PactBroker.docker_configuration.port.to_i + 1).to_s

port PactBroker.docker_configuration.port

metrics_url "tcp://0.0.0.0:#{puma_metrics_port}"

if PactBroker.docker_configuration.puma_persistent_timeout
  persistent_timeout PactBroker.docker_configuration.puma_persistent_timeout
end
