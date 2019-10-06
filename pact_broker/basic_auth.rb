class BasicAuth
  PATH_INFO = 'PATH_INFO'.freeze
  REQUEST_METHOD = 'REQUEST_METHOD'.freeze
  GET = 'GET'.freeze
  OPTIONS = 'OPTIONS'.freeze
  HEAD = 'HEAD'.freeze
  BADGE_PATH = %r{^/pacts/provider/[^/]+/consumer/.*/badge(?:\.[A-Za-z]+)?$}.freeze
  HEARTBEAT_PATH = "/diagnostic/status/heartbeat".freeze

  def initialize(app, write_user_username, write_user_password, read_user_username, read_user_password, allow_public_access_to_heartbeat)
    @app = app
    @write_user_username = write_user_username
    @write_user_password = write_user_password
    @read_user_username = read_user_username
    @read_user_password = read_user_password
    @allow_public_access_to_heartbeat = allow_public_access_to_heartbeat

    @app_with_write_auth = Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
      username == @write_user_username && password == @write_user_password
    end

    @app_with_read_auth = if read_user_username && read_user_username.size > 0
      Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
        (username == @write_user_username && password == @write_user_password) ||
          (username == @read_user_username && password == @read_user_password)
      end
    else
      puts "WARN: Public read access is enabled as no PACT_BROKER_BASIC_AUTH_READ_ONLY_USERNAME has been set"
      app
    end
  end

  def call(env)
    if use_basic_auth? env
      if read_request?(env)
        @app_with_read_auth.call(env)
      else
        @app_with_write_auth.call(env)
      end
    else
      @app.call(env)
    end
  end

  def read_request?(env)
    env.fetch(REQUEST_METHOD) == GET || env.fetch(REQUEST_METHOD) == OPTIONS || env.fetch(REQUEST_METHOD) == HEAD
  end

  def use_basic_auth?(env)
    !allow_public_access(env)
  end

  def allow_public_access(env)
    env[PATH_INFO] =~ BADGE_PATH || is_heartbeat_and_public_access_allowed?(env)
  end

  def is_heartbeat_and_public_access_allowed?(env)
    @allow_public_access_to_heartbeat && env[PATH_INFO] == HEARTBEAT_PATH
  end
end
