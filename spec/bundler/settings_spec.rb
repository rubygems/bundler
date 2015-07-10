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

  describe "#groups_conflict?" do
    context "when two arrays have same value" do
      it "returns true" do
        array1 = %i(alpha beta gamma)
        array2 = %i(gamma delta epsilon)
        expect( settings.groups_conflict? array1, array2 ).to be_truthy
      end
    end
    context "when two arrays don't share values" do
      it "returns false" do
        array1 = %i(alpha beta gamma)
        array2 = %i(delta epsilon zeta)
        expect( settings.groups_conflict? array1, array2 ).to be_falsy
      end
    end
  end

  describe "#with" do
    it "returns all with keys" do
      settings.set_with %i(beta gamma), :config => :local
      settings.set_with %i(delta alpha)
      expect(settings.with).to include(:alpha, :beta, :gamma, :delta)
    end

    it "overrides all other without groups" do
      settings.set_without %i(beta gamma), :config => :local
      settings.set_with %i(delta beta)
      expect(settings.with).to include(:beta)
    end
  end

  describe "#without" do
    it "returns all with keys" do
      settings.set_without %i(beta gamma), :config => :local
      settings.set_without %i(delta alpha)
      expect(settings.without).to include(:alpha, :beta, :gamma, :delta)
    end

    it "overrides all other with groups" do
      settings.set_with %i(beta gamma), :config => :local
      settings.set_without %i(delta beta)
      expect(settings.without).to include(:beta)
    end
  end

  describe "#set_with" do
    it "allows setting any config" do
      settings.set_with %i(beta gamma), :config => :local
      expect(settings.locations(:with)).to have_key(:local)
    end

    context "when same level groups conflict" do
      it "raises an error" do
        settings.set_without %i(beta gamma), :config => :local
        expect{settings.set_with(%i(delta beta), :config => :local)}.to raise_error ArgumentError
      end
    end
  end

  describe "#set_without" do
    it "allows setting any config" do
      settings.set_without %i(beta gamma), :config => :local
      expect(settings.locations(:without)).to have_key(:local)
    end

    context "when same level groups conflict" do
      it "raises an error" do
        settings.set_with %i(beta gamma), :config => :local
        expect{settings.set_without(%i(delta beta), :config => :local)}.to raise_error ArgumentError
      end
    end
  end

end
