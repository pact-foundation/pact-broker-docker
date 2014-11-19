require 'fileutils'
require 'logger'
require 'sequel'
require 'pact_broker'

# Create a real database, and set the credentials for it here
DATABASE_CREDENTIALS = {database: "pact_broker_database", adapter: "postgres", user: ENV['DB_USERNAME'], password: ENV['DB_PASSWORD'], host: ENV['DB_HOST'], database: ENV['DB_NAME']}

app = PactBroker::App.new do | config |
  # change these from their default values if desired
  # config.log_dir = "./log"
  # config.auto_migrate_db = true
  # config.use_hal_browser = true
  config.database_connection = Sequel.connect(DATABASE_CREDENTIALS.merge(logger: config.logger, encoding: 'utf8'))
end

run app
