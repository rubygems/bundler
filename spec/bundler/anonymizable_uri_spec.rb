require 'spec_helper'
require 'bundler/anonymizable_uri'

describe Bundler::AnonymizableURI do
  let(:anonymizable_uri) { Bundler::AnonymizableURI.new(original_uri) }

  describe "#without_credentials" do
    context "when the original URI has no credentials" do
      let(:original_uri) { URI('https://rubygems.org') }

      it "returns the original URI" do
        expect(anonymizable_uri.without_credentials).to eq(original_uri)
      end
    end

    context "when the original URI has a username and password" do
      let(:original_uri) { URI("https://username:password@gems.example.com") }

      it "returns the URI without username and password" do
        expect(anonymizable_uri.without_credentials).to eq(URI("https://gems.example.com"))
      end
    end

    context "when the original URI has only a username" do
      let(:original_uri) { URI("https://SeCrEt-ToKeN@gem.fury.io/me/") }

      it "returns the URI without username and password" do
        expect(anonymizable_uri.without_credentials).to eq(URI("https://gem.fury.io/me/"))
      end
    end
  end
end
