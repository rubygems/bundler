require "spec_helper"

describe "bundle install" do
  describe "with --force" do
    before :each do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "install"
    end

    it "re-installs installed gems" do
      bundle "install --force"
      expect(out).to include "Installing rack 1.0.0"
      should_be_installed "rack 1.0.0"
    end
  end
end
