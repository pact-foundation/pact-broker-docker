$: << "."
require "pact_broker/docker_configuration"
require 'rspec/its'

RSpec.describe PactBroker::DockerConfiguration do

  subject { PactBroker::DockerConfiguration.new(env, default_configuration) }

  let(:env) do
    {
      "PACT_BROKER_WEBHOOK_HOST_WHITELIST" => host_whitelist,
      "PACT_BROKER_ORDER_VERSIONS_BY_DATE" => "false"
    }
  end

  let(:host_whitelist) { "" }

  let(:default_configuration) do
    instance_double('default configuration',
      webhook_host_whitelist: 'default'
    )
  end

  describe "pact_broker_environment_variables" do
    let(:env) do
      {
        "PACT_BROKER_FOO" => "foo",
        "PACT_BROKER_PASSWORD" => "bar",
        "SOMETHING" => "foo"
      }
    end

    context "when the environment variables contains an arbitrary key" do
      let(:expected_environment_variables) do
        {
          "PACT_BROKER_FOO" => "foo",
          "PACT_BROKER_PASSWORD" => "*****"
        }
      end

      its(:pact_broker_environment_variables) { is_expected.to eq expected_environment_variables }
    end

    context "when the environment variables contain database keys" do
      let(:db_env) do
        {
          "PACT_BROKER_DATABASE_HOST" => "localhost"
        }
      end
      let(:env) do
        super().merge(db_env)
      end

      let(:expected_environment_variables) do
        {
          "PACT_BROKER_FOO" => "foo",
          "PACT_BROKER_PASSWORD" => "*****"
        }
      end

      its(:pact_broker_environment_variables) { is_expected.to have_key "PACT_BROKER_FOO" }
      its(:pact_broker_environment_variables) { is_expected.to have_key "PACT_BROKER_PASSWORD" }
      its(:pact_broker_environment_variables) { is_expected.to have_key "PACT_BROKER_DATABASE_HOST" }
      its(:pact_broker_environment_variables) { is_expected.not_to have_key "SOMETHING" }
      it { expect(subject.pact_broker_environment_variables["PACT_BROKER_PASSWORD"]).to eq "*****" }
    end

    context "when the environment variables contain a database url key" do
      let(:db_env) do
        {
          "PACT_BROKER_DATABASE_URL" => "postgresql://pactbrokeruser:TheUserPassword@localhost:5432/pactbroker"
        }
      end
      let(:env) do
        super().merge(db_env)
      end

      let(:expected_environment_variables) do
        {
          "PACT_BROKER_FOO" => "foo",
          "PACT_BROKER_PASSWORD" => "*****"
        }
      end

      its(:pact_broker_environment_variables) { is_expected.to have_key "PACT_BROKER_DATABASE_URL" }
      its(:pact_broker_environment_variables) { is_expected.not_to have_key "SOMETHING" }
      it { expect(subject.pact_broker_environment_variables["PACT_BROKER_PASSWORD"]).to eq "*****" }
    end
  end

  describe "database_configuration" do
    let(:env) { super().merge(db_env) }

    context "when then configuration is provided as a URL" do
      let(:db_env) do
        {
          "PACT_BROKER_DATABASE_URL" => "postgresql://pactbrokeruser:TheUserPassword@localhost:5432/pactbroker"
        }
      end

      its(:database_configuration) { is_expected.to be_a Hash }
      its("database_configuration.keys") { are_expected.to include :adapter, :user, :password, :host, :database, :encoding, :port }
      it { expect(subject.database_configuration[:user]).to eq "pactbrokeruser" }
      it { expect(subject.database_configuration[:password]).to eq "TheUserPassword" }
      it { expect(subject.database_configuration[:host]).to eq "localhost" }
      it { expect(subject.database_configuration[:database]).to eq "pactbroker" }
      it { expect(subject.database_configuration[:encoding]).to eq "utf8" }
      it { expect(subject.database_configuration[:port]).to eq 5432 }
    end

    context "when then configuration is provided in separate env vars" do
      let(:db_env) do
        {
          "PACT_BROKER_DATABASE_USERNAME" => "pactbrokeruser",
          "PACT_BROKER_DATABASE_PASSWORD" => "TheUserPassword",
          "PACT_BROKER_DATABASE_HOST" => "localhost",
          "PACT_BROKER_DATABASE_NAME" => "pactbroker",
        }
      end

      its(:database_configuration) { is_expected.to be_a Hash }
      its("database_configuration.keys") { are_expected.to include :adapter, :user, :password, :host, :database, :encoding }
      it { expect(subject.database_configuration[:user]).to eq "pactbrokeruser" }
      it { expect(subject.database_configuration[:password]).to eq "TheUserPassword" }
      it { expect(subject.database_configuration[:host]).to eq "localhost" }
      it { expect(subject.database_configuration[:database]).to eq "pactbroker" }
      it { expect(subject.database_configuration[:encoding]).to eq "utf8" }

      context "when an adapter is supplied" do
        let(:db_env) { super().merge("PACT_BROKER_DATABASE_ADAPTER" => "mysql") }

        it { expect(subject.database_configuration[:adapter]).to eq "mysql" }
      end

      context "when an adapter is not supplied" do
        it { expect(subject.database_configuration[:adapter]).to eq "postgres" }
      end

      context "when a port is supplied" do
        let(:db_env) { super().merge("PACT_BROKER_DATABASE_PORT" => port) }

        context "and the value is numeric" do
          let(:port) { "1234" }

          it { expect(subject.database_configuration[:port]).to eq 1234 }
        end

        context "and the value is not numeric" do
          let(:port) { "abc" }

          its("database_configuration.keys") { are_expected.not_to include :port }
        end
      end

      context "when a port is not supplied" do
        its("database_configuration.keys") { are_expected.not_to include :port }
      end
    end
  end

  describe "order_versions_by_date" do
    context "when PACT_BROKER_ORDER_VERSIONS_BY_DATE is set to false" do
      its(:order_versions_by_date) { is_expected.to be false }
    end

    context "when PACT_BROKER_ORDER_VERSIONS_BY_DATE is not set" do
      let(:env) { {} }
      its(:order_versions_by_date) { is_expected.to be true }
    end
  end

  describe "webhook_host_whitelist" do
    context "when PACT_BROKER_WEBHOOK_HOST_WHITELIST is 'foo bar'" do
      let(:host_whitelist) { "foo bar" }
      its(:webhook_host_whitelist) { is_expected.to eq ["foo", "bar"] }
    end

    context "when PACT_BROKER_WEBHOOK_HOST_WHITELIST is ''" do
      let(:host_whitelist) { "" }
      its(:webhook_host_whitelist) { is_expected.to eq 'default' }
    end
  end
end

class PactBroker::DockerConfiguration
  describe SpaceDelimitedStringList do
    describe "parse" do
      subject { SpaceDelimitedStringList.parse(input) }

      context "when input is ''" do
        let(:input) { "" }

        it { is_expected.to eq [] }

        its(:to_s) { is_expected.to eq input }
      end

      context "when input is 'foo bar'" do
        let(:input) { "foo bar" }

        it { is_expected.to eq ["foo", "bar"] }

        it { is_expected.to be_a SpaceDelimitedStringList }

        its(:to_s) { is_expected.to eq input }
      end

      context "when input is '/foo.*/'" do
        let(:input) { "/foo.*/" }

        it { is_expected.to eq [/foo.*/] }

        its(:to_s) { is_expected.to eq input }
      end

      context "when input is '/foo\\.*/' (note double backslash)" do
        let(:input) { "/foo\\.*/" }

        it { is_expected.to eq [/foo\.*/] }

        its(:to_s) { is_expected.to eq input }
      end
    end
  end
end
