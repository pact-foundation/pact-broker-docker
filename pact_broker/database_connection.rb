require 'sequel'
require_relative 'database_logger'

def create_database_connection(logger)
  database_adapter = ENV.fetch('PACT_BROKER_DATABASE_ADAPTER','') != '' ? ENV['PACT_BROKER_DATABASE_ADAPTER'] : 'postgres'

  credentials = {
    adapter: database_adapter,
    user: ENV['PACT_BROKER_DATABASE_USERNAME'],
    password: ENV['PACT_BROKER_DATABASE_PASSWORD'],
    host: ENV['PACT_BROKER_DATABASE_HOST'],
    database: ENV['PACT_BROKER_DATABASE_NAME']
  }

  if ENV['PACT_BROKER_DATABASE_PORT'] =~ /^\d+$/
    credentials[:port] = ENV['PACT_BROKER_DATABASE_PORT'].to_i
  end

  Sequel.connect(credentials.merge(logger: DatabaseLogger.new(logger), encoding: 'utf8'))
end
