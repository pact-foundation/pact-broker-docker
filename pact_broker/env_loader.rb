require "anyway"

# Copied from https://github.com/palkan/anyway_config/blob/4165ff3cb3a385707319eb210925842353418300/lib/anyway/env.rb
module PactBroker
  class Env
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

  # Copied from https://github.com/palkan/anyway_config/blob/4165ff3cb3a385707319eb210925842353418300/lib/anyway/loaders/env.rb
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
end
