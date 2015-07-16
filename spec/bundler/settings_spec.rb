require 'spec_helper'
require 'bundler/settings'

describe Bundler::Settings do
  subject(:settings) { described_class.new(bundled_app) }

  describe "#set_local" do
    context "when the local config file is not found" do
      subject(:settings) { described_class.new(nil) }

      it "raises a GemfileNotFound error with explanation" do
        expect{ subject.set_local("foo", "bar") }.
          to raise_error(Bundler::GemfileNotFound, "Could not locate Gemfile")
      end
    end
  end

  describe "#[]=" do
    if Bundler::VERSION.split(".")[0].to_i >= 2
      context "when on Bundler 2.0" do
        it "should not write to local config file" do
          settings[:foo] = :bar
          expect(settings.locations(:foo)[:local]).to be_nil
        end
      end
    else
      context "when not on Bundler 2.0" do
        it "should not write to local config file" do
          settings[:foo] = :bar
          expect(settings.locations(:foo)[:local]).to eq(:bar)
        end
      end
    end
  end

  describe "#[]" do
    context "when not set" do
      context "when default value present" do
        it "retrieves value" do
          expect(settings[:retry]).to be 3
        end
      end

      it "returns nil" do
        expect(settings[:buttermilk]).to be nil
      end
    end

    context "when is boolean" do
      it "returns a boolean" do
        settings[:frozen] = "true"
        expect(settings[:frozen]).to be true
      end
      context "when specific gem is configured" do
        it "returns a boolean" do
          settings["ignore_messages.foobar"] = "true"
          expect(settings["ignore_messages.foobar"]).to be true
        end
      end
    end
  end


  describe "#mirror_for" do
    let(:uri) { URI("https://rubygems.org/") }

    context "with no configured mirror" do
      it "returns the original URI" do
        expect(settings.mirror_for(uri)).to eq(uri)
      end

      it "converts a string parameter to a URI" do
        expect(settings.mirror_for("https://rubygems.org/")).to eq(uri)
      end
    end

    context "with a configured mirror" do
      let(:mirror_uri) { URI("https://rubygems-mirror.org/") }

      before { settings["mirror.https://rubygems.org/"] = mirror_uri.to_s }

      it "returns the mirror URI" do
        expect(settings.mirror_for(uri)).to eq(mirror_uri)
      end

      it "converts a string parameter to a URI" do
        expect(settings.mirror_for("https://rubygems.org/")).to eq(mirror_uri)
      end

      it "normalizes the URI" do
        expect(settings.mirror_for("https://rubygems.org")).to eq(mirror_uri)
      end

      it "is case insensitive" do
        expect(settings.mirror_for("HTTPS://RUBYGEMS.ORG/")).to eq(mirror_uri)
      end
    end
  end

  describe "#credentials_for" do
    let(:uri) { URI("https://gemserver.example.org/") }
    let(:credentials) { "username:password" }

    context "with no configured credentials" do
      it "returns nil" do
        expect(settings.credentials_for(uri)).to be_nil
      end
    end

    context "with credentials configured by URL" do
      before { settings["https://gemserver.example.org/"] = credentials }

      it "returns the configured credentials" do
        expect(settings.credentials_for(uri)).to eq(credentials)
      end
    end

    context "with credentials configured by hostname" do
      before { settings["gemserver.example.org"] = credentials }

      it "returns the configured credentials" do
        expect(settings.credentials_for(uri)).to eq(credentials)
      end
    end
  end

  describe "a flag passed to a command" do
    it "is not automatically remembered" do
      # Ensure we're in a Bundler environment that forgets flags between cmds
      bundle "config use_current true"

      install_gemfile <<-G, :path => "some/path/"
        source "file://#{gem_repo1}"
        gem "rack"
      G

      expect(bundled_app("some/path")).to exist
      FileUtils.rm_r(bundled_app("some/path"))
      expect(bundled_app("some/path")).not_to exist

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      expect(bundled_app("some/path")).not_to exist
      expect(default_bundle_path("gems/rack-1.0.0")).to exist
      should_be_installed("rack 1.0.0")
    end

    it "is remembered if set with config" do
      bundle "config use_current true"

      bundle "config path 'another/directory'"
      expect(bundled_app("another/directory")).not_to exist

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      expect(bundled_app("another/directory")).to exist
      expect(bundled_app("another/directory/gems/rack-1.0.0")).to exist
      should_be_installed("rack 1.0.0")
    end
  end

  describe "URI normalization" do
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
