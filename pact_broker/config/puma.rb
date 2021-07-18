require_relative "../docker_configuration_2"

# port ENV[ENV['PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME']]
port PactBroker.docker_configuration.port

if PactBroker.docker_configuration.puma_persistent_timeout
  persistent_timeout PactBroker.docker_configuration.puma_persistent_timeout
end
