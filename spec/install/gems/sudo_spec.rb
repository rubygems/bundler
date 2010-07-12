require "spec_helper"

describe "when using sudo" do
  before :each do
    pending "set BUNDLER_SUDO_TESTS to run sudo specs" unless test_sudo?
    chown_system_gems_to_root
  end

  describe "bundle install with GEM_HOME owned by root" do
    it "works" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      system_gem_path("gems/rack-1.0.0").should exist
      system_gem_path("gems/rack-1.0.0").stat.uid.should == 0
      should_be_installed "rack 1.0"
    end

    it "works when BUNDLE_PATH does not exist" do
      bundle_path = tmp("owned_by_root")
      FileUtils.mkdir_p bundle_path
      sudo "chown -R root #{bundle_path}"

      ENV['BUNDLE_PATH'] = bundle_path
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      bundle_path.join("gems/rack-1.0.0").should exist
      bundle_path.join("gems/rack-1.0.0").stat.uid.should == 0
      should_be_installed "rack 1.0"
    end
  end
end