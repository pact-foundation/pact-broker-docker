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

    let(:expected_environment_variables) do
      {
        "PACT_BROKER_FOO" => "foo",
        "PACT_BROKER_PASSWORD" => "*****"
      }
    end

    its(:pact_broker_environment_variables) { is_expected.to eq expected_environment_variables }
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
