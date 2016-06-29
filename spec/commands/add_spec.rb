# frozen_string_literal: true
require "spec_helper"

describe "bundle add" do
  before :each do
    build_repo2

    gemfile <<-G
      source "file://#{gem_repo2}"
    G
  end

  context "when version number is set" do
    it "adds gem with provided version" do
      bundle "add activesupport 2.3.5"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 2.3.5'")
    end

    it "adds gem with provided version and version operator" do
      update_repo2 do
        build_gem "activesupport", "3.0.0"
      end

      bundle "add activesupport '> 2.3.5'"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '> 2.3.5'")
    end
  end

  context "when version number is not set" do
    it "adds gem with last stable version" do
      bundle "add activesupport"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 2.3.5'")
    end

    it "adds the gem with the last prerelease version" do
      update_repo2 do
        build_gem "activesupport", "3.0.0"
        build_gem "activesupport", "3.0.0.beta"
      end

      bundle "add activesupport --pre"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 3.0.0.beta'")
    end
  end

  context "when group is set" do
    it "adds the gem with the specified groups" do
      bundle "add activesupport --group development test"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 2.3.5', :group => [:development, :test]")
    end
  end

  context "when source is set" do
    it "adds the gem with a specified source" do
      bundle "add activesupport --source file://#{gem_repo2}"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 2.3.5', :source => 'file:\/\/#{gem_repo2}'")
    end
  end

  context "when multiple options are set" do
    before :each do
      update_repo2 do
        build_gem "activesupport", "3.0.0"
      end
    end

    it "adds the gem with a specified group and source" do
      bundle "add activesupport --group test --source file://#{gem_repo2}"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 3.0.0', :group => [:test], :source => 'file:\/\/#{gem_repo2}'")
    end

    it "adds the gem with a specified version, group, and source" do
      bundle "add activesupport 2.3.5 --group development --source file://#{gem_repo2}"
      expect(bundled_app("Gemfile").read).to include("gem 'activesupport', '~> 2.3.5', :group => [:development], :source => 'file:\/\/#{gem_repo2}'")
    end
  end
end
