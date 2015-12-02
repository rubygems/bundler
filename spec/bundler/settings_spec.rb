require "spec_helper"
require "bundler/settings"

describe Bundler::Settings do
  subject(:settings) { described_class.new(bundled_app) }

  describe "#set_local" do
    context "when the local config file is not found" do
      subject(:settings) { described_class.new(nil) }

      it "raises a GemfileNotFound error with explanation" do
        expect { subject.set_local("foo", "bar") }.
          to raise_error(Bundler::GemfileNotFound, "Could not locate Gemfile")
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

    context "when is number" do
      it "returns a number" do
        settings[:ssl_verify_mode] = "1"
        expect(settings[:ssl_verify_mode]).to be 1
      end
    end

    context "when it's not possible to write to the file" do
      it "raises an PermissionError with explanation" do
        expect(FileUtils).to receive(:mkdir_p).with(settings.send(:local_config_file).dirname).
          and_raise(Errno::EACCES)
        expect { settings[:frozen] = "1" }.
          to raise_error(Bundler::PermissionError, /config/)
      end
    end
  end

  describe "#set_global" do
    context "when it's not possible to write to the file" do
      it "raises an PermissionError with explanation" do
        expect(FileUtils).to receive(:mkdir_p).with(settings.send(:global_config_file).dirname).
          and_raise(Errno::EACCES)
        expect { settings.set_global(:frozen, "1") }.
          to raise_error(Bundler::PermissionError, %r{\.bundle/config})
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

      context "with a fallback timeout" do
        before { settings["mirror.https://rubygems.org.fallback_timeout"] = 1 }

        it "still returns the mirror correctly" do
          expect(settings.mirror_for(uri)).to eq(mirror_uri)
        end

        it "returns the fallback timeout" do
          expect(settings.gem_mirrors[uri].fallback_timeout).to eq(1)
        end

        it "has the uri and the fallback timeout" do
          expect(settings.gem_mirrors.to_h).to eq(uri => Mirror.new(mirror_uri, 1))
        end
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
      expect(settings.gem_mirrors.to_h).to eq(URI("https://rubygems.org/") => Mirror.new(URI("http://rubygems-mirror.org/")))
    end
  end

  describe "BUNDLE_ keys format" do
    let(:settings) { described_class.new(bundled_app(".bundle")) }

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
