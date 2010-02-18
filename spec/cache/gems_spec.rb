require File.expand_path('../../spec_helper', __FILE__)

describe "bundle cache with gems" do
  describe "when there are only gemsources" do
    before :each do
      gemfile <<-G
        gem 'rack'
      G

      system_gems "rack-1.0.0"
      bundle :cache
    end

    it "copies the .gem file to vendor/cache" do
      bundled_app("vendor/cache/rack-1.0.0.gem").should exist
    end

    it "uses the cache as a source when installing gems" do
      system_gems []
      bundle :install

      should_be_installed("rack 1.0.0")
    end
  end

  describe "when there are also git sources" do
    it "still works" do
      build_git "foo"
      system_gems "rack-1.0.0"

      install_gemfile <<-G
        git "#{lib_path("foo-1.0")}"
        gem 'rack'
        gem 'foo'
      G

      bundle :cache

      system_gems []
      bundle :install

      should_be_installed("rack 1.0.0", "foo 1.0")
    end
  end

end