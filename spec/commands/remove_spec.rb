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

  context "removes empty block on removal of all gems from it" do
    it "when single block with gem is present" do
      gemfile <<-G
        source "file://#{gem_repo1}"

        group :test do
          gem "minitest"
        end
      G

      bundle "remove minitest"

      expect(gemfile).to_not match(/group :test do/)
      expect(gemfile).to_not match(/gem "minitest"/)
      expect(out).to include("minitest(>= 0) was removed.")
    end

    it "when any other empty block is also present" do
      gemfile <<-G
        source "file://#{gem_repo1}"

        group :test do
          gem "minitest"
        end

        group :dev do

        end
      G

      bundle "remove minitest"

      expect(gemfile).to_not match(/group :test do/)
      expect(gemfile).to_not match(/gem "minitest"/)
      expect(gemfile).to_not match(/group :dev do/)
      expect(out).to include("minitest(>= 0) was removed.")
    end
  end
end
