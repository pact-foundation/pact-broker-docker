# @private - do not rely on these classes as a public interface
require_relative "env_loader"

Anyway.loaders.insert_after :env, :custom_env, PactBroker::Loaders::Env

require "pact_broker/config/runtime_configuration"

module PactBroker
  def self.docker_configuration
    @@docker_configuration ||= DockerConfiguration.new
  end

  class DockerConfiguration < PactBroker::Config::RuntimeConfiguration
    attr_config(
      log_stream: :stdout,
      enable_public_badge_access: true,
      puma_persistent_timeout: nil
    )

    # these need to be set again after extending the class
    sensitive_values(*PactBroker::Config::RuntimeConfiguration.sensitive_values)

    def log_stream= log_stream
      super(log_stream&.to_sym)
    end

    def puma_persistent_timeout= puma_persistent_timeout
      super(puma_persistent_timeout&.to_i)
    end
  end
end
