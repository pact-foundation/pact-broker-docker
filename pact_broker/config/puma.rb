require_relative "../docker_configuration"

bind "tcp://0.0.0.0:#{PactBroker.docker_configuration.port}"
bind "tcp://[::]:#{PactBroker.docker_configuration.port}"

if PactBroker.docker_configuration.puma_persistent_timeout
  persistent_timeout PactBroker.docker_configuration.puma_persistent_timeout
end
