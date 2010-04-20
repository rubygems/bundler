require "spec_helper"

describe "bundle pack with gems" do
  describe "when there are only gemsources" do
    before :each do
      gemfile <<-G
        gem 'rack'
      G

      system_gems "rack-1.0.0"
      bundle :pack
    end

    it "locks the gemfile" do
      bundled_app("Gemfile.lock").should exist
    end

    it "caches the gems" do
      bundled_app("vendor/cache/rack-1.0.0.gem").should exist
    end
  end
end