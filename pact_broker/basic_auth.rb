class BasicAuth
  PATH_INFO = 'PATH_INFO'.freeze
  REQUEST_METHOD = 'REQUEST_METHOD'.freeze
  GET = 'GET'.freeze
  OPTIONS = 'OPTIONS'.freeze
  HEAD = 'HEAD'.freeze
  READ_METHODS = [GET, OPTIONS, HEAD].freeze
  PACT_BADGE_PATH = %r{^/pacts/provider/[^/]+/consumer/.*/badge(?:\.[A-Za-z]+)?$}.freeze
  MATRIX_BADGE_PATH = %r{^/matrix/provider/[^/]+/latest/[^/]+/consumer/[^/]+/latest/[^/]+/badge(?:\.[A-Za-z]+)?$}.freeze
  HEARTBEAT_PATH = "/diagnostic/status/heartbeat".freeze

  def initialize(app, write_user_username, write_user_password, read_user_username, read_user_password, allow_public_read_access, allow_public_access_to_heartbeat)
    @app = app
    @write_credentials = [write_user_username, write_user_password]
    @read_credentials = [read_user_username, read_user_password]
    @allow_public_access_to_heartbeat = allow_public_access_to_heartbeat
    @app_with_write_auth = build_app_with_write_auth
    @app_with_read_auth = build_app_with_read_auth(allow_public_read_access)
  end

  def call(env)
    if use_basic_auth? env
      if read_request?(env)
        app_with_read_auth.call(env)
      else
        app_with_write_auth.call(env)
      end
    else
      app.call(env)
    end
  end

  protected

  def write_credentials_match(*credentials)
    credentials == write_credentials
  end

  def read_credentials_match(*credentials)
    is_set(read_credentials[0]) && credentials == read_credentials
  end

  private

  attr_reader :app, :app_with_read_auth, :app_with_write_auth, :write_credentials, :read_credentials, :allow_public_access_to_heartbeat

  def build_app_with_write_auth
    this = self
    Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
      this.write_credentials_match(username, password)
    end
  end

  def build_app_with_read_auth(allow_public_read_access)
    if allow_public_read_access
      puts "INFO: Public read access is enabled"
      app
    else
      this = self
      Rack::Auth::Basic.new(app, "Restricted area") do |username, password|
        this.write_credentials_match(username, password) || this.read_credentials_match(username, password)
      end
    end
  end

  def read_request?(env)
    READ_METHODS.include?(env[REQUEST_METHOD])
  end

  def use_basic_auth?(env)
    !allow_public_access(env)
  end

  def allow_public_access(env)
    env[PATH_INFO] =~ PACT_BADGE_PATH || env[PATH_INFO] =~ MATRIX_BADGE_PATH || is_heartbeat_and_public_access_allowed?(env)
  end

  def is_heartbeat_and_public_access_allowed?(env)
    allow_public_access_to_heartbeat && env[PATH_INFO] == HEARTBEAT_PATH
  end

  def is_set(string)
    string && string.strip.size > 0
  end
end
