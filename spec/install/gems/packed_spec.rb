require File.expand_path('../../../spec_helper', __FILE__)

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
  end
end