require File.expand_path('../../../spec_helper', __FILE__)

describe "bundle install with gem sources" do
  describe "when cached and locked" do
    it "does not hit the remote at all" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      bundle :pack
      simulate_new_machine
      FileUtils.rm_rf gem_repo2

      bundle :install
      should_be_installed "rack 1.0.0"
    end

    it "does not reinstall already-installed gems" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      bundle :pack

      build_gem "rack", "1.0.0", :path => bundled_app('vendor/cache') do |s|
        s.write "lib/rack.rb", "raise 'omg'"
      end

      bundle :install
      err.should be_empty
      should_be_installed "rack 1.0"
    end
  end

  describe "when cached" do
    it "ignores cached gems for the wrong platform" do
      install_gemfile <<-G
        Gem.platforms = [#{java}]
        source "file://#{gem_repo1}"
        gem "platform_specific"
      G
      bundle :cache
      simulate_new_machine

      install_gemfile <<-G
        Gem.platforms = [#{rb}]
        source "file://#{gem_repo1}"
        gem "platform_specific"
      G
      bundle :install
      run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
      out.should == "1.0.0 RUBY"
    end

    it "updates the cache during later installs" do
      cached_gem = bundled_app("vendor/cache/rack-1.0.0.gem")
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle :cache
      cached_gem.should exist

      FileUtils.rm_rf(cached_gem)

      bundle :install
      out.should include("Copying .gem files into vendor/cache")
      cached_gem.should exist
    end
  end
end