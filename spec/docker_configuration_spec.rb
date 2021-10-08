require_relative "../pact_broker/docker_configuration"
require 'anyway/testing/helpers'

RSpec.describe PactBroker::DockerConfiguration do
  include ::Anyway::Testing::Helpers

  around do |ex|
    env = {
      "PACT_BROKER_DATABASE_URL_ENVIRONMENT_VARIABLE_NAME" => "DATABASE_URL",
      "DATABASE_URL" => "some_url",
      "PACT_BROKER_PORT_ENVIRONMENT_VARIABLE_NAME" => "HTTP_PORT",
      "HTTP_PORT" => "5000"
    }
    with_env(env, &ex)
  end

  subject { PactBroker::Loaders::CustomEnv.new(local: false).call(env_prefix: "pact_broker") }

  it "loads the database URL from the named environment variable" do
    expect(subject).to include "database_url"=>"some_url"
  end

  it "loads the port from the named environment variable" do
    expect(subject).to include "port"=> 5000
  end
end
