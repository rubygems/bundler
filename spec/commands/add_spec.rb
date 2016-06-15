# frozen_string_literal: true
require "pry-byebug"
require "spec_helper"

describe "bundle add" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"
    G
  end

  context "when version number is set" do
    it "adds gem with provided version" do
      bundle "add 'rack-obama' '1.0'"
      expect(bundled_app("Gemfile").read).to match(/gem 'rack-obama', '= 1.0'/)
    end

    it "adds gem with provided version and version operator" do
      bundle "add 'rack-obama' '> 0'"
      expect(bundled_app("Gemfile").read).to match(/gem 'rack-obama', '> 0'/)
    end
  end

  context "when version number is not set" do
    it "adds gem with last stable version" do
      bundle "add 'rack-obama'"
      expect(bundled_app("Gemfile").read).to match(/gem 'rack-obama', '= 1.0'/)
    end
  end
end
