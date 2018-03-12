class BasicAuth
  PATH_INFO = 'PATH_INFO'.freeze
  BADGE_PATH = %r{^/pacts/provider/[^/]+/consumer/.*/badge(?:\.[A-Za-z]+)?$}.freeze
  HEARTBEAT_PATH = "/diagnostic/status/heartbeat".freeze

  def initialize(app, username, password, allow_public_access_to_heartbeat)
    @app = app
    @expected_username = username
    @expected_password = password
    @allow_public_access_to_heartbeat = allow_public_access_to_heartbeat

    @app_with_auth = Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
      username == @expected_username && password == @expected_password
    end
  end

  def call(env)
    if use_basic_auth? env
      @app_with_auth.call(env)
    else
      @app.call(env)
    end
  end

  def use_basic_auth?(env)
    !(is_badge_path?(env) || is_heartbeat_and_public_access_allowed?(env))
  end

  def is_badge_path?(env)
    env[PATH_INFO] =~ BADGE_PATH
  end

  def is_heartbeat_and_public_access_allowed?(env)
    @allow_public_access_to_heartbeat && env[PATH_INFO] == HEARTBEAT_PATH
  end
end
