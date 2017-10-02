class BasicAuth
  PATH_INFO = 'PATH_INFO'
  BADGE_PATH = %r{^/pacts/provider/[^/]+/consumer/.*/badge(?:\.[A-Za-z]+)?$}

  def initialize(app, username, password)
    @app = app
    @expected_username = username
    @expected_password = password

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
    !(env[PATH_INFO] =~ BADGE_PATH)
  end
end
