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

  describe "global" do
    before(:each) { bundle :install }

    it "is the default" do
      bundle "config2 set foo global"
      run "puts Bundler.settings[:foo]"
      expect(out).to eq("global")
    end

    it "can also be set explicitly" do
      bundle! "config2 --global set foo global"
      run! "puts Bundler.settings[:foo]"
      expect(out).to eq("global")
    end

    it "has lower precedence than local" do
      bundle "config2 --local set foo local"

      bundle "config2 --global set foo global"
      expect(out).to match(/Your application has set foo to "local"/)

      run "puts Bundler.settings[:foo]"
      expect(out).to eq("local")
    end

    it "can be unset" do
      bundle "config2 unset --global foo global"
      bundle "config2 unset foo"

      run "puts Bundler.settings[:foo] == nil"
      expect(out).to eq("true")
    end

    it "warns when overriding" do
      bundle "config2 set --global foo previous"
      bundle "config2 set --global foo global"
      expect(out).to match(/You are replacing the current global value of foo/)

      run "puts Bundler.settings[:foo]"
      expect(out).to eq("global")
    end

    it "does not warn when using the same value twice" do
      bundle "config2 set --global foo value"
      bundle "config2 set --global foo value"
      expect(out).not_to match(/You are replacing the current global value of foo/)

      run "puts Bundler.settings[:foo]"
      expect(out).to eq("value")
    end


    it "expands the path at time of setting" do
      bundle "config --global local.foo .."
      run "puts Bundler.settings['local.foo']"
      expect(out).to eq(File.expand_path(Dir.pwd + "/.."))
    end

  end

end
