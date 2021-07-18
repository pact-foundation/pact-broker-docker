# @private - do not rely on these classes as a public interface
require "pact_broker/version" #TODO delete this
require "pact_broker/config/runtime_configuration"

config_dir = ENV.fetch("PACT_BROKER_CONFIG_DIR", "")

if config_dir != ""
  if File.exist?(config_dir) && File.directory?(config_dir)
    Anyway::Settings.default_config_path = config_dir
    puts "Setting configuration directory to #{config_dir}"
  else
    puts "WARN: Cannot use configuration directory at #{config_dir} because it does not exist or is not a directory."
  end
end

module PactBroker
  class Env
    using Anyway::Ext::DeepDup
    using Anyway::Ext::Hash

    using Anyway::Ext::DeepDup
    using Anyway::Ext::Hash

    include Anyway::Tracing

    attr_reader :data, :traces, :type_cast

    def initialize(type_cast: Anyway::AutoCast)
      @type_cast = type_cast
      @data = {}
      @traces = {}
    end

    def clear
      data.clear
      traces.clear
    end

    def fetch(prefix)
      return data[prefix].deep_dup if data.key?(prefix)

      Anyway::Tracing.capture do
        data[prefix] = parse_env(prefix)
      end.then do |trace|
        traces[prefix] = trace
      end

      data[prefix].deep_dup
    end

    def fetch_with_trace(prefix)
      [fetch(prefix), traces[prefix]]
    end
    private

    def parse_env(prefix)
      match_prefix = "#{prefix}_"
      ENV.each_pair.with_object({}) do |(key, val), data|
        if key == ENV["PACT_BROKER_DATABASE_URL_ENVIRONMENT_VARIABLE_NAME"]
          map_to_attribute("database_url", key, val, data)
        elsif key == ENV["PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME"]
          map_to_attribute("port", key, val, data)
        end
      end
    end

    def map_to_attribute(path, key, val, data)
      paths = [path]
      trace!(:env, *paths, key: key) { data.bury(type_cast.call(val), *paths) }
    end
  end

  module Loaders
    class Env < Anyway::Loaders::Env
      def call(env_prefix:, **_options)
        PactBroker::Env.new.fetch_with_trace(env_prefix).then do |(conf, trace)|
          Anyway::Tracing.current_trace&.merge!(trace)
          conf
        end
      end
    end
  end

  Anyway.loaders.insert_after :env, :custom_env, PactBroker::Loaders::Env

  def self.docker_configuration
    @@docker_configuration ||= DockerConfiguration2.new
  end

  class DockerConfiguration2 < PactBroker::Config::RuntimeConfiguration
    config_name :pact_broker

    attr_config(
      port: 9292,
      log_level: :info,
      log_format: nil,
      puma_persistent_timeout: nil
    )

    def log_level= log_level
      super(log_level&.downcase&.to_sym)
    end

    def log_format= log_format
      super(log_format&.to_sym)
    end

    def puma_persistent_timeout= puma_persistent_timeout
      super(puma_persistent_timeout&.to_i)
    end

    def log_environment_variables(logger)
      pact_broker_environment_variables.each do | (key, value) |
        logger.info "#{key}=#{value}"
      end
    end

    def log_configuration(logger)
      logger.info "------------------------------------------------------------------------"
      logger.info "PACT BROKER CONFIGURATION:"
      to_source_trace.sort_by { |key, value| key }.each { |key, value| log_config_inner(key, value, logger) }
      logger.info "------------------------------------------------------------------------"
    end

    def log_config_inner(key, value, logger)
      if !value.has_key? :value
        value.sort_by { |inner_key, value| key }.each { |inner_key, value| log_config_inner("#{key}:#{inner_key}", value) }
      else
        logger.info "#{key}=#{maybe_redact(key.to_s, value[:value])} [#{value[:source]}]"
      end
    end

    private

    def pact_broker_environment_variables
      pact_broker_environment_variable_names.sort.each_with_object({}) do | name, hash |
        value = @env[name]
        # special case: suppress password of database connection string, if present
        if name == "PACT_BROKER_DATABASE_URL" && value =~ /:\/\/[^:]+:[^@]+@/
          hash[name] = value.sub(/(:\/\/[^:]+):[^@]+@/, '\1:*****@')
        else
          hash[name] = name =~ /password/i ? "*****" : value
        end
      end
    end

    def pact_broker_environment_variable_names
      remapped_env_var_names = @env.keys.select { |k| k.start_with?('PACT_BROKER_') && k.end_with?('_ENVIRONMENT_VARIABLE_NAME') }
      @env.keys.select{ |k| k.start_with?('PACT_BROKER_') } + remapped_env_var_names.collect{ |name| @env[name] }.compact
    end
  end
end
