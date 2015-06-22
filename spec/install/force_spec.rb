require "spec_helper"

describe "bundle install" do
  describe "with --force" do
    before :each do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    it "re-installs installed gems" do
      bundle "install"
      bundle "install --force"

      expect(out).to include "Installing rack 1.0.0"
      should_be_installed "rack 1.0.0"
      expect(exitstatus).to eq(0) if exitstatus
    end

    it "doesn't reinstall bundler" do
      bundle "install"
      bundle "install --force"
      expect(out).to_not include "Installing bundler 1.10.4"
      expect(out).to include "Using bundler 1.10.4"
    end

  end
end
