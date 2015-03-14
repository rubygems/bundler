require "spec_helper"
require "bundler/source/rubygems/remote"

describe Bundler::Source::Rubygems::Remote do
  def remote(uri, auth = nil)
    Bundler::Source::Rubygems::Remote.new(uri, auth)
  end

  let(:uri_no_auth) { URI("https://gems.example.com") }
  let(:uri_with_auth) { URI("https://username:password@gems.example.com") }

  context "when the original URI has no credentials" do
    describe "#uri" do
      it "returns the original URI" do
        expect(remote(uri_no_auth).uri).to eq(uri_no_auth)
      end

      it "applies given credentials" do
        expect(remote(uri_no_auth, "username:password").uri).to eq(uri_with_auth)
      end
    end

    describe "#anonymized_uri" do
      it "returns the original URI" do
        expect(remote(uri_no_auth).anonymized_uri).to eq(uri_no_auth)
      end

      it "does not apply given credentials" do
        expect(remote(uri_no_auth, "username:password").anonymized_uri).to eq(uri_no_auth)
      end
    end
  end

  context "when the original URI has a username and password" do
    describe "#uri" do
      it "returns the original URI" do
        expect(remote(uri_with_auth).uri).to eq(uri_with_auth)
      end

      it "does not apply given credentials" do
        expect(remote(uri_with_auth, "other:stuff").uri).to eq(uri_with_auth)
      end
    end

    describe "#anonymized_uri" do
      it "returns the URI without username and password" do
        expect(remote(uri_with_auth).anonymized_uri).to eq(uri_no_auth)
      end

      it "does not apply given credentials" do
        expect(remote(uri_with_auth, "other:stuff").anonymized_uri).to eq(uri_no_auth)
      end
    end
  end

  context "when the original URI has only a username" do
    let(:uri) { URI("https://SeCrEt-ToKeN@gem.fury.io/me/") }

    describe "#anonymized_uri" do
      it "returns the URI without username and password" do
        expect(remote(uri).anonymized_uri).to eq(URI("https://gem.fury.io/me/"))
      end
    end
  end
end
