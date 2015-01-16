require "spec_helper"

describe "bundle cache" do
  before do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  context "with --cache-path" do
    it "caches gems at given path" do
      bundle :cache, "cache-path" => "vendor/cache-foo"
      expect(bundled_app("vendor/cache-foo/rack-1.0.0.gem")).to exist
    end
  end

  context "with BUNDLE_CACHE_PATH" do
    it "caches gems at given path" do
      ENV["BUNDLE_CACHE_PATH"] = "vendor/cache-bar"
      bundle :cache
      expect(bundled_app("vendor/cache-bar/rack-1.0.0.gem")).to exist
    end
  end

  context "when given an absolute path" do
    it "prints an error" do
      out = bundle :cache, "cache-path" => "/tmp/cache-foo"
      expect(out).to match(/must be relative/)
    end

    it "exits with non-zero status" do
      exit_status = bundle :cache, "cache-path" => "/tmp/cache-foo", :exitstatus => true
      expect(exit_status).to eq(1)
    end
  end
end
