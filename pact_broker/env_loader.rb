require "anyway"

# From https://github.com/palkan/anyway_config/blob/4165ff3cb3a385707319eb210925842353418300/lib/anyway/env.rb
module PactBroker
  class Env < Anyway::Env
    using Anyway::Ext::Hash

    private

    def parse_env(prefix)
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

  # From https://github.com/palkan/anyway_config/blob/4165ff3cb3a385707319eb210925842353418300/lib/anyway/loaders/env.rb
  module Loaders
    class CustomEnv < Anyway::Loaders::Env
      def call(env_prefix:, **_options)
        PactBroker::Env.new.fetch_with_trace(env_prefix).then do |(conf, trace)|
          Anyway::Tracing.current_trace&.merge!(trace)
          conf
        end
      end
    end
  end
end
