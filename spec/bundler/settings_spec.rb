require 'spec_helper'
require 'bundler/settings'

describe Bundler::Settings do
  describe "#set_local" do
    context "when the local config file is not found" do
      it "raises a GemfileNotFound error with explanation" do
        expect{ subject.set_local("foo", "bar") }.
          to raise_error(Bundler::GemfileNotFound, "Could not locate Gemfile")
      end
    end
  end

  describe "URI normalization" do
    let(:settings) { described_class.new(bundled_app) }

    it "normalizes HTTP URIs in credentials configuration" do
      settings["http://gemserver.example.org"] = "username:password"
      expect(settings.all).to include("http://gemserver.example.org/")
    end

    it "normalizes HTTPS URIs in credentials configuration" do
      settings["https://gemserver.example.org"] = "username:password"
      expect(settings.all).to include("https://gemserver.example.org/")
    end

    it "normalizes HTTP URIs in mirror configuration" do
      settings["mirror.http://rubygems.org"] = "http://rubygems-mirror.org"
      expect(settings.all).to include("mirror.http://rubygems.org/")
    end

    it "normalizes HTTPS URIs in mirror configuration" do
      settings["mirror.https://rubygems.org"] = "http://rubygems-mirror.org"
      expect(settings.all).to include("mirror.https://rubygems.org/")
    end

    it "does not normalize other config keys that happen to contain 'http'" do
      settings["local.httparty"] = home("httparty")
      expect(settings.all).to include("local.httparty")
    end

    it "does not normalize other config keys that happen to contain 'https'" do
      settings["local.httpsmarty"] = home("httpsmarty")
      expect(settings.all).to include("local.httpsmarty")
    end

    it "reads older keys without trailing slashes" do
      settings["mirror.https://rubygems.org"] = "http://rubygems-mirror.org"
      expect(settings.gem_mirrors).to eq(URI("https://rubygems.org/") => URI("http://rubygems-mirror.org/"))
    end
  end

  describe "BUNDLE_ keys format" do
    let(:settings) { described_class.new(bundled_app('.bundle')) }

    it "converts older keys without double dashes" do
      config("BUNDLE_MY__PERSONAL.RACK" => "~/Work/git/rack")
      expect(settings["my.personal.rack"]).to eq("~/Work/git/rack")
    end

    it "converts older keys without trailing slashes and double dashes" do
      config("BUNDLE_MIRROR__HTTPS://RUBYGEMS.ORG" => "http://rubygems-mirror.org")
      expect(settings["mirror.https://rubygems.org/"]).to eq("http://rubygems-mirror.org")
    end

    it "reads newer keys format properly" do
      config("BUNDLE_MIRROR__HTTPS://RUBYGEMS__ORG/" => "http://rubygems-mirror.org")
      expect(settings["mirror.https://rubygems.org/"]).to eq("http://rubygems-mirror.org")
    end
  end
end
