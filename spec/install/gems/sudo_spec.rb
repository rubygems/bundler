require "spec_helper"

describe "when using sudo" do
  before :each do
    pending "set BUNDLER_SUDO_TESTS to run sudo specs" unless test_sudo?
  end

  describe "and GEM_HOME is owned by root" do
    before :each do
      chown_system_gems_to_root
    end

    it "installs" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      system_gem_path("gems/rack-1.0.0").should exist
      system_gem_path("gems/rack-1.0.0").stat.uid.should == 0
      should_be_installed "rack 1.0"
    end

    it "installs when BUNDLE_PATH is owned by root" do
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

    it "installs when BUNDLE_PATH does not exist"
  end

  describe "and BUNDLE_PATH is not writable" do
    it "installs" do
      sudo "chmod ugo-w #{default_bundle_path}"
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      default_bundle_path("gems/rack-1.0.0").should exist
      should_be_installed "rack 1.0"
    end
  end

end