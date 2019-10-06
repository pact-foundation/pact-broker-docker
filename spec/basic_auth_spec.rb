require_relative "../pact_broker/basic_auth"
require "rack/test"

RSpec.describe "basic auth" do

  include Rack::Test::Methods

  let(:protected_app) { ->(env) { [200, {}, []]} }

  let(:app) { BasicAuth.new(protected_app, 'write_username', 'write_password', read_username, read_password, allow_public_access_to_heartbeat) }
  let(:read_username) { 'read_username' }
  let(:read_password) { 'read_password' }
  let(:allow_public_access_to_heartbeat) { true }


  context "when requesting the heartbeat" do
    let(:path) { "/diagnostic/status/heartbeat" }

    context "when allow_public_access_to_heartbeat is true" do
      context "when no credentials are used" do
        it "allows GET" do
          get path
          expect(last_response.status).to eq 200
        end
      end
    end

    context "when allow_public_access_to_heartbeat is false" do
      let(:allow_public_access_to_heartbeat) { false }

      context "when no credentials are used" do
        it "does not allow GET" do
          get path
          expect(last_response.status).to eq 401
        end
      end

      context "when the correct credentials are used" do
        it "allows GET" do
          basic_authorize 'read_username', 'read_password'
          get path
          expect(last_response.status).to eq 200
        end
      end
    end
  end

  context "when requesting a badge" do
    context "when no credentials are used" do
      it "allows GET" do
        get "pacts/provider/foo/consumer/bar/badge"
        expect(last_response.status).to eq 200
      end
    end
  end

  context "with the correct username and password for the write user" do
    it "allows GET" do
      basic_authorize 'write_username', 'write_password'
      get "/"
      expect(last_response.status).to eq 200
    end

    it "allows POST" do
      basic_authorize 'write_username', 'write_password'
      post "/"
      expect(last_response.status).to eq 200
    end

    it "allows HEAD" do
      basic_authorize 'write_username', 'write_password'
      head "/"
      expect(last_response.status).to eq 200
    end

    it "allows OPTIONS" do
      basic_authorize 'write_username', 'write_password'
      options "/"
      expect(last_response.status).to eq 200
    end

    it "allows PUT" do
      basic_authorize 'write_username', 'write_password'
      delete "/"
      expect(last_response.status).to eq 200
    end

    it "allows PATCH" do
      basic_authorize 'write_username', 'write_password'
      patch "/"
      expect(last_response.status).to eq 200
    end

    it "allows DELETE" do
      basic_authorize 'write_username', 'write_password'
      delete "/"
      expect(last_response.status).to eq 200
    end
  end

  context "with the incorrect username and password for the write user" do
    it "does not allow POST" do
      basic_authorize 'foo', 'password'
      post "/"
      expect(last_response.status).to eq 401
    end
  end

  context "with the correct username and password for the read user" do
    it "allows GET" do
      basic_authorize 'read_username', 'read_password'
      get "/"
      expect(last_response.status).to eq 200
    end

    it "allows OPTIONS" do
      basic_authorize 'read_username', 'read_password'
      options "/"
      expect(last_response.status).to eq 200
    end

    it "allows HEAD" do
      basic_authorize 'read_username', 'read_password'
      head "/"
      expect(last_response.status).to eq 200
    end

    it "does not allow POST" do
      basic_authorize 'read_username', 'read_password'
      post "/"
      expect(last_response.status).to eq 401
    end

    it "does not allow PUT" do
      basic_authorize 'read_username', 'read_password'
      put "/"
      expect(last_response.status).to eq 401
    end

    it "does not allow PATCH" do
      basic_authorize 'read_username', 'read_password'
      patch "/"
      expect(last_response.status).to eq 401
    end

    it "does not allow DELETE" do
      basic_authorize 'read_username', 'read_password'
      delete "/"
      expect(last_response.status).to eq 401
    end
  end

  context "with the incorrect username and password for the write user" do
    it "does not allow GET" do
      basic_authorize 'write_username', 'wrongpassword'
      get "/"
      expect(last_response.status).to eq 401
    end
  end

  context "with the incorrect username and password for the read user" do
    it "does not allow GET" do
      basic_authorize 'read_username', 'wrongpassword'
      get "/"
      expect(last_response.status).to eq 401
    end
  end

  context "with a request to the badge URL" do
    context "with no credentials" do
      it "allows GET" do
        get "/pacts/provider/foo/consumer/bar/badge"
        expect(last_response.status).to eq 200
      end
    end
  end

  context "when there is no read only user configured" do
    before do
      allow($stdout).to receive(:puts)
    end

    let(:read_username) { '' }
    let(:read_password) { '' }

    context "with no credentials" do
      it "allows a GET" do
        get "/"
        expect(last_response.status).to eq 200
      end
    end

    context "with incorrect credentials" do
      it "allows a GET" do
        basic_authorize "foo", "bar"
        get "/"
        expect(last_response.status).to eq 200
      end
    end
  end
end
