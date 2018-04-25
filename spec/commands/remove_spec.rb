# frozen_string_literal: true

RSpec.describe "bundle remove", :focus do
  context "remove a specific gem from gemfile when gem is present in gemfile" do
    before do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
        gem "rack"
      G
    end

    it "removes successfully" do
      bundle "remove rack"
      expect(out).to include("rack(>= 0) was removed.")
    end

    it "displays warning that gemfile is empty when removing last gem" do
      bundle "remove rails"
      bundle "remove rack"
      expect(out).to include("rack(>= 0) was removed.")
      expect(out).to include("The Gemfile specifies no dependencies")
    end
  end

  context "remove a specific gem from gemfile when gem is not present in gemfile" do
    before do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
      G
    end

    it "throws error" do
      bundle "remove rack"
      expect(out).to include("You cannot remove a gem which not specified in Gemfile.")
      expect(out).to include("rack is not specified in Gemfile so not removed.")
    end
  end
end
