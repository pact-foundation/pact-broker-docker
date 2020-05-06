require 'sequel'
require_relative 'database_logger'

DB_ENV_VAR_NAME = ENV.fetch('PACT_BROKER_DATABASE_URL_ENVIRONMENT_VARIABLE_NAME', 'PACT_BROKER_DATABASE_URL')
URL = ENV[DB_ENV_VAR_NAME]
SSL_MODE = ENV.fetch('PACT_BROKER_DATABASE_SSLMODE','')
ADAPTER = ENV.fetch('PACT_BROKER_DATABASE_ADAPTER','') != '' ? ENV['PACT_BROKER_DATABASE_ADAPTER'] : 'postgres'
USERNAME = ENV['PACT_BROKER_DATABASE_USERNAME']
PASSWORD = ENV['PACT_BROKER_DATABASE_PASSWORD']
HOST = ENV['PACT_BROKER_DATABASE_HOST']
NAME = ENV['PACT_BROKER_DATABASE_NAME']
PORT = ENV['PACT_BROKER_DATABASE_PORT']

def create_database_connection(logger)
  non_credential_options = {
    encoding: 'utf8',
    logger: DatabaseLogger.new(logger)
  }
  non_credential_options[:sslmode] = SSL_MODE if SSL_MODE != ''

  connection = if URL
    uri = URI(URL)
    uri.password = "*****"
    logger.info "Connecting to database #{uri} with config: #{non_credential_options}"
    Sequel.connect(URL, non_credential_options)
  else
    config = {
      adapter: ADAPTER,
      user: USERNAME,
      password: PASSWORD,
      host: HOST,
      database: NAME,
    }.merge(non_credential_options)

    config[:port] = PORT.to_i if PORT =~ /^\d+$/

    logger.info "Connecting to database with config: #{config.merge(password: "*****")}"
    Sequel.connect(config)
  end

  ##
  # Sequel by default does not test connections in its connection pool before
  # handing them to a client. To enable connection testing you need to load the
  # "connection_validator" extension like below. The connection validator
  # extension is configurable, by default it only checks connections once per
  # hour:
  #
  # http://sequel.rubyforge.org/rdoc-plugins/files/lib/sequel/extensions/connection_validator_rb.html
  #
  #
  # A gotcha here is that it is not enough to enable the "connection_validator"
  # extension, we also need to specify that we want to use the threaded connection
  # pool, as noted in the documentation for the extension.
  #
  # -1 means that connections will be validated every time, which avoids errors
  # when databases are restarted and connections are killed.  This has a performance
  # penalty, so consider increasing this timeout if building a frequently accessed service.

  connection.extension(:connection_validator)
  connection.pool.connection_validation_timeout = -1
  connection
end
