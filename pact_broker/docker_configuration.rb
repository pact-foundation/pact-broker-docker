# @private - do not rely on these classes as a public interface

module PactBroker
  class DockerConfiguration
    def initialize env, default_configuration
      @env = env
      @default_configuration = default_configuration
    end

    def pact_broker_environment_variables
      pact_broker_environment_variable_names.sort.each_with_object({}) do | name, hash |
        hash[name] = name =~ /password/i ? "*****" : @env[name]
      end
    end

    def pact_broker_environment_variable_names
      remapped_env_var_names = @env.keys.select { |k| k.start_with?('PACT_BROKER_') && k.end_with?('_ENVIRONMENT_VARIABLE_NAME') }
      @env.keys.select{ |k| k.start_with?('PACT_BROKER_') } + remapped_env_var_names.collect{ |name| @env[name] }.compact
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

    def webhook_http_code_success
      space_delimited_integer_list_or_default(:webhook_http_code_success)
    end

    def webhook_retry_schedule
      space_delimited_integer_list_or_default(:webhook_retry_schedule)
    end

    def database_configuration
      if database_url
        database_configuration_from_url
      else
        database_configuration_from_parts
      end.merge(
        encoding: 'utf8',
        sslmode: env_or_nil(:database_sslmode),
        sql_log_level: (env_or_nil(:sql_log_level) || 'debug').downcase.to_sym,
        log_warn_duration: (env_or_nil(:sql_log_warn_duration) || '5').to_f,
        max_connections: env_as_integer(:database_max_connections),
        pool_timeout: env_as_integer(:database_pool_timeout)
      ).compact
    end

    def database_connect_max_retries
      env_as_integer(:database_connect_max_retries, 0)
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

    def env_or_nil name
      env_populated?(name) ? env(name) : nil
    end

    def env_as_integer name, default = nil
      env_populated?(name) ? env(name).to_i : default
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

    def space_delimited_integer_list_or_default property_name
      if env_populated?(property_name)
        SpaceDelimitedIntegerList.parse(env(property_name))
      else
        default(property_name)
      end
    end

    class SpaceDelimitedIntegerList < Array
      def initialize list
        super(list)
      end

      def self.integer?(string)
        (Integer(string) rescue nil) != nil
      end

      def self.parse(string)
        array = (string || '')
                    .split(' ')
                    .filter { |word| integer?(word) }
                    .collect(&:to_i)
        SpaceDelimitedIntegerList.new(array)
      end

      def to_s
        collect(&:to_s).join(' ')
      end
    end

    private

    def database_url
      @database_url ||= @env[env_or_nil(:database_url_environment_variable_name) || 'PACT_BROKER_DATABASE_URL']
    end

    def database_configuration_from_parts
      database_adapter = env_or_nil(:database_adapter) || 'postgres'

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
      uri = URI(database_url)

      {
        adapter: uri.scheme,
        user: uri.user,
        password: uri.password,
        host: uri.host,
        database: uri.path.sub(/^\//, ''),
        port: uri.port&.to_i,
      }.compact
    end
  end
end
