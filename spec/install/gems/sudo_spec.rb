require "spec_helper"

describe "when using sudo", :sudo => true do
  describe "and GEM_HOME is owned by root" do
    before :each do
      chown_system_gems_to_root
    end

    it "installs" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
        gem "thin"
      G

      system_gem_path("gems/rack-1.0.0").should exist
      system_gem_path("gems/rack-1.0.0").stat.uid.should eq(0)
      should_be_installed "rack 1.0"
    end

    it "installs when BUNDLE_PATH is owned by root" do
      bundle_path = tmp("owned_by_root")
      FileUtils.mkdir_p bundle_path
      sudo "chown -R root #{bundle_path}"

      ENV['BUNDLE_PATH'] = bundle_path.to_s
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      bundle_path.join("gems/rack-1.0.0").should exist
      bundle_path.join("gems/rack-1.0.0").stat.uid.should eq(0)
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

  describe "and BUNDLE_PATH is not writable" do
    it "installs" do
      begin
        gem_home = tmp('sudo_gem_home')

        sudo "mkdir -p #{gem_home}"
        sudo "chmod ugo-w #{gem_home}"
        ENV['GEM_HOME'] = gem_home.to_s
        ENV['GEM_PATH'] = nil

        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack", '1.0'
        G

        gem_home.join('bin/rackup').should exist
        should_be_installed "rack 1.0"
      end
    end
  end

end
