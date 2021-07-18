# @private - do not rely on these classes as a public interface
require "pact_broker/version" #TODO delete this
require "pact_broker/config/runtime_configuration"
require_relative "env_loader"

config_dir = ENV.fetch("PACT_BROKER_CONFIG_DIR", "")

if config_dir != ""
  if File.exist?(config_dir) && File.directory?(config_dir)
    Anyway::Settings.default_config_path = config_dir
    puts "Setting configuration directory to #{config_dir}"
  else
    puts "WARN: Cannot use configuration directory at #{config_dir} because it does not exist or is not a directory."
  end
end

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
