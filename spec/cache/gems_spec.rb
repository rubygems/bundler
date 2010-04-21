require File.expand_path('../../spec_helper', __FILE__)

describe "bundle cache" do

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

    it "does not reinstall gems from the cache if they exist on the system" do
      build_gem "rack", "1.0.0", :path => bundled_app('vendor/cache') do |s|
        s.write "lib/rack.rb", "RACK = 'FAIL'"
      end

      install_gemfile <<-G
        gem "rack"
      G

      should_be_installed("rack 1.0.0")
    end

    it "does not reinstall gems from the cache if they exist in the bundle" do
      system_gems []
      install_gemfile <<-G
        gem "rack"
      G

      build_gem "rack", "1.0.0", :path => bundled_app('vendor/cache') do |s|
        s.write "lib/rack.rb", "RACK = 'FAIL'"
      end

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

  describe "when previously cached" do
    before :each do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
        gem "actionpack"
      G
      bundle :cache
      cached_gem("rack-1.0.0").should exist
      cached_gem("actionpack-2.3.2").should exist
      cached_gem("activesupport-2.3.2").should exist
    end

    it "re-caches during install" do
      cached_gem("rack-1.0.0").rmtree
      bundle :install
      out.should include("Copying .gem files into vendor/cache")
      cached_gem("rack-1.0.0").should exist
    end

    it "adds updated gems" do
      update_repo2
      bundle :install
      cached_gem("rack-1.2").should exist
    end

    it "adds new gems and dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails"
      G
      cached_gem("rails-2.3.2").should exist
      cached_gem("activerecord-2.3.2").should exist
    end

    it "removes .gems for removed gems and dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G
      cached_gem("rack-1.0.0").should exist
      cached_gem("actionpack-2.3.2").should_not exist
      cached_gem("activesupport-2.3.2").should_not exist
    end

    it "doesn't remove gems that are for another platform" do
      install_gemfile <<-G
        Gem.platforms = [#{java}]
        source "file://#{gem_repo1}"
        gem "platform_specific"
      G
      bundle :cache
      cached_gem("platform_specific-1.0-java").should exist

      simulate_new_machine
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "platform_specific"
      G
      cached_gem("platform_specific-1.0-#{Gem::Platform.local}").should exist
      cached_gem("platform_specific-1.0-java").should exist
    end

    it "doesn't remove gems with mismatched :rubygems_version or :date" do
      cached_gem("rack-1.0.0").rmtree
      build_gem "rack", "1.0.0",
        :path => bundled_app('vendor/cache'),
        :rubygems_version => "1.3.2"
      simulate_new_machine

      bundle :install
      cached_gem("rack-1.0.0").should exist
    end
  end

end