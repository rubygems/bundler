# frozen_string_literal: true
require "spec_helper"

describe "bundle info" do
  context "info from specific gem in gemfile" do
    before :each do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
      G
    end

    it "should print summary of rake gem" do
      bundle "info rails"

      expect(out).to include("rails")
      expect(out).to include("\tSummary:")
      expect(out).to include("\tHomepage:")
      expect(out).to include("\tStatus:")
      expect(out).to include("\tPath:")
    end

    it "should create a Gemfile.lock if not existing" do
      FileUtils.rm("Gemfile.lock")

      bundle "info rails"

      expect(bundled_app("Gemfile.lock")).to exist
    end

    it "should show error message if gem not found" do
      bundle "info anything"

      expect(out).to eql("Could not find gem 'anything'.")
    end
  end
end
