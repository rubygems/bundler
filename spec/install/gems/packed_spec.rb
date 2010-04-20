require "spec_helper"

describe "bundle install with gem sources" do
  describe "when cached and locked" do
    it "does not hit the remote at all" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      bundle :lock
      bundle :cache

      system_gems []
      FileUtils.rm_rf gem_repo2

      bundle :install
      should_be_installed "rack 1.0.0"
    end

    it "does not constantly reinstall the gems" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "pack"

      build_gem "rack", "1.0.0", :path => bundled_app('vendor/cache') do |s|
        s.write "lib/rack.rb", "raise 'omg'"
      end

      bundle "install"

      err.should be_empty
      should_be_installed "rack 1.0"
    end

    it "updates the cache if it exists" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      cached_gem = bundled_app("vendor/cache/rack-1.0.0.gem")
      bundle "pack"
      FileUtils.rm_rf(cached_gem)
      bundle "install"

      out.should include("Copying .gem files into vendor/cache")
      cached_gem.should exist
    end
  end
end