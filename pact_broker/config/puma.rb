require_relative "../docker_configuration"

port PactBroker.docker_configuration.port

if PactBroker.docker_configuration.puma_persistent_timeout
  persistent_timeout PactBroker.docker_configuration.puma_persistent_timeout
end
