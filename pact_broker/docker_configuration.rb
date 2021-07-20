# @private - do not rely on these classes as a public interface
require "pact_broker/config/runtime_configuration"
require_relative "env_loader"

Anyway.loaders.insert_after :env, :custom_env, PactBroker::Loaders::Env

module PactBroker
  def self.docker_configuration
    @@docker_configuration ||= DockerConfiguration.new
  end

  class DockerConfiguration < PactBroker::Config::RuntimeConfiguration
    config_name :pact_broker

    attr_config(
      port: 9292,
      log_level: :info,
      log_format: nil,
      puma_persistent_timeout: nil
    )

    # these need to be set again after inheriting
    sensitive_values(:database_url, :database_password)

    def log_level= log_level
      super(log_level&.downcase&.to_sym)
    end

    def log_format= log_format
      super(log_format&.to_sym)
    end

    def puma_persistent_timeout= puma_persistent_timeout
      super(puma_persistent_timeout&.to_i)
    end
  end
end
