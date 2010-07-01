require "spec_helper"

describe 'omg' do
  describe_sudo "bundle install with GEM_HOME owned by root" do
    it "works" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      system_gem_path("gems/rack-1.0.0").should exist
      File.stat(system_gem_path("gems/rack-1.0.0")).uid.should == 0
      should_be_installed "rack 1.0"
    end

    it "works during the first time when BUNDLE_PATH does not exist" do
      bundle_path = "#{tmp}/owned_by_root"
      ENV['BUNDLE_PATH'] = bundle_path

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", '1.0'
      G

      tmp("owned_by_root/gems/rack-1.0.0").should exist
      should_be_installed "rack 1.0"
    end
  end
end