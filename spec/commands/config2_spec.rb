# frozen_string_literal: true
require "spec_helper"

RSpec.describe ".bundle/config2" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", "1.0.0"
    G
  end

  describe "BUNDLE_APP_CONFIG" do
    it "can be moved with an environment variable" do
      ENV["BUNDLE_APP_CONFIG"] = tmp("foo/bar").to_s
      bundle "install --path vendor/bundle"

      expect(bundled_app(".bundle")).not_to exist
      expect(tmp("foo/bar/config")).to exist
      expect(the_bundle).to include_gems "rack 1.0.0"
    end

    it "can provide a relative path with the environment variable" do
      FileUtils.mkdir_p bundled_app("omg")
      Dir.chdir bundled_app("omg")

      ENV["BUNDLE_APP_CONFIG"] = "../foo"
      bundle "install --path vendor/bundle"

      expect(bundled_app(".bundle")).not_to exist
      expect(bundled_app("../foo/config")).to exist
      expect(the_bundle).to include_gems "rack 1.0.0"
    end
  end

  context "no option" do
    describe "set"
    describe "unset"
    describe "no command"
  end

  context "--global" do
    describe "set"
    describe "unset"
    describe "no command"
  end

  context "--local" do
    describe "set"
    describe "unset"
    describe "no command"
  end
  
end
