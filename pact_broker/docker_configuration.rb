# @private - do not rely on these classes as a public interface

module PactBroker
  class DockerConfiguration
    def initialize env, default_configuration
      @env = env
      @default_configuration = default_configuration
    end

    def pact_broker_environment_variables
      @env.each_with_object({}) do | (key, value), hash |
        if key.start_with?("PACT_BROKER_")
          hash[key] = key =~ /password/i ? "*****" : value
        end
      end
    end

    def webhook_host_whitelist
      space_delimited_string_list_or_default(:webhook_host_whitelist)
    end

    def webhook_scheme_whitelist
      space_delimited_string_list_or_default(:webhook_scheme_whitelist)
    end

    def webhook_http_method_whitelist
      space_delimited_string_list_or_default(:webhook_http_method_whitelist)
    end

    def database_configuration
      if env_populated?(:database_url)
        database_configuration_from_url
      else
        database_configuration_from_parts
      end.merge(encoding: 'utf8', sslmode: env(:database_sslmode)).compact
    end

    def base_equality_only_on_content_that_affects_verification_results
      if env_populated?(:base_equality_only_on_content_that_affects_verification_results)
        env(:base_equality_only_on_content_that_affects_verification_results) == 'true'
      else
        default(:base_equality_only_on_content_that_affects_verification_results)
      end
    end

    def disable_ssl_verification
      env(:disable_ssl_verification) == 'true'
    end

    def order_versions_by_date
      if env_populated?(:order_versions_by_date)
        env(:order_versions_by_date) == 'true'
      else
        true
      end
    end

    def base_url
      env(:base_url)
    end

    def env name
      @env["PACT_BROKER_#{name.to_s.upcase}"]
    end

    def env_populated? name
      (env(name) || "").size > 0
    end

    def default property_name
      @default_configuration.send(property_name)
    end

    def space_delimited_string_list_or_default property_name
      if env_populated?(property_name)
        SpaceDelimitedStringList.parse(env(property_name))
      else
        default(property_name)
      end
    end

    class SpaceDelimitedStringList < Array

      def initialize list
        super(list)
      end

      def self.parse(string)
        array = (string || '').split(' ').collect do | word |
          if word[0] == '/' and word[-1] == '/'
            Regexp.new(word[1..-2])
          else
            word
          end
        end
        SpaceDelimitedStringList.new(array)
      end

      def to_s
        collect do | word |
          if word.is_a?(Regexp)
            "/#{word.source}/"
          else
            word
          end
        end.join(' ')
      end
    end

    private

    def database_configuration_from_parts
      database_adapter = if env_populated?(:database_adapter)
                           env(:database_adapter)
                         else
                           'postgres'
                         end

      config = {
        adapter: database_adapter,
        user: env(:database_username),
        password: env(:database_password),
        host: env(:database_host),
        database: env(:database_name),
      }

      if env(:database_port) =~ /^\d+$/
        config[:port] = env(:database_port).to_i
      end

      config
    end

    def database_configuration_from_url
      uri = URI(env(:database_url))

      {
        adapter: uri.scheme,
        user: uri.user,
        password: uri.password,
        host: uri.host,
        database: uri.path.sub(/^\//, ''),
        port: (uri.port || 5432).to_i,
      }.compact
    end
  end
end
