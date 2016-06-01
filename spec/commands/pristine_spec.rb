# frozen_string_literal: true
require "spec_helper"
describe "bundle pristine" do
  context "when the Gemfile is missing" do
    it "should provide useful information" do
      bundle "pristine"
      expect(out).to include "You can't pristine without a Gemfile. Please consider add Gemfile"
      expect(out).to include "Could not locate Gemfile"
    end
  end

  context "when the Gemfile is present and Gemfile.lock is missing" do
    before :each do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0"
        gem "foo", "1.2.3"
      G
    end
    it "should provide useful information" do
      bundle "pristine"
      expect(out).to include "You can't pristine without a Gemfile.lock. Please consider run `bundle install`"
      expect(out).to include "Could not locate Gemfile.lock"
    end
  end

  context "when both the Gemfile and the Gemfile.lock is present" do
    before :each do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0"
        gem "foo", "1.2.3"
      G
    end
  end
end
