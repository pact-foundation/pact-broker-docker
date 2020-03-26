require 'sequel'
require_relative 'database_logger'

def create_database_connection(logger)
  database_adapter = ENV.fetch('PACT_BROKER_DATABASE_ADAPTER','') != '' ? ENV['PACT_BROKER_DATABASE_ADAPTER'] : 'postgres'

  config = {
    adapter: database_adapter,
    user: ENV['PACT_BROKER_DATABASE_USERNAME'],
    password: ENV['PACT_BROKER_DATABASE_PASSWORD'],
    host: ENV['PACT_BROKER_DATABASE_HOST'],
    database: ENV['PACT_BROKER_DATABASE_NAME'],
    sql_log_level: ENV.fetch('PACT_BROKER_SQL_LOG_LEVEL', 'debug').to_sym,
    log_warn_duration: ENV.fetch('PACT_BROKER_SQL_LOG_WARN_DURATION', '5').to_f,
    encoding: 'utf8',
    logger: DatabaseLogger.new(logger)
  }

  if ENV.fetch('PACT_BROKER_DATABASE_SSLMODE','') != ''
    config[:sslmode] = ENV['PACT_BROKER_DATABASE_SSLMODE']
  end

  if ENV['PACT_BROKER_DATABASE_PORT'] =~ /^\d+$/
    config[:port] = ENV['PACT_BROKER_DATABASE_PORT'].to_i
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
  logger.info "Connecting to database with config: #{config.merge(password: "*****")}"
  connection = Sequel.connect(config)
  connection.extension(:connection_validator)
  connection.pool.connection_validation_timeout = -1
  connection
end
