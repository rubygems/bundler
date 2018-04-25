# frozen_string_literal: true

RSpec.describe "bundle remove" do
  context "remove a single gem from gemfile" do
    it "when gem is present in gemfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"

        gem "rack"
      G

      bundle "remove rack"

      expect(gemfile).to_not match(/gem "rack"/)
      expect(out).to include("rack(>= 0) was removed.")
    end

    it "when gem is not present in gemfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
      G

      bundle "remove rack"

      expect(out).to include("You cannot remove a gem which not specified in Gemfile.")
      expect(out).to include("rack is not specified in Gemfile so not removed.")
    end
  end

  context "remove mutiple gems from gemfile" do
    it "when all gems are present in gemfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"

        gem "rack"
        gem "rails"
      G

      bundle "remove rack rails"

      expect(gemfile).to_not match(/gem "rack"/)
      expect(gemfile).to_not match(/gem "rails"/)
      expect(out).to include("rack(>= 0) was removed.")
      expect(out).to include("rails(>= 0) was removed.")
    end

    it "when a gem is not present in gemfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"

        gem "rails"
      G

      bundle "remove rack rails"
      expect(out).to include("You cannot remove a gem which not specified in Gemfile.")
      expect(out).to include("rack is not specified in Gemfile so not removed.")
    end
  end
end
