# frozen_string_literal: true
require "spec_helper"

RSpec.describe "bundle install with a gemfile that forces a gem version" do
  context "with a simple conflict" do
    it "works" do
      install_gemfile! <<-G
        source "file:#{gem_repo1}"
        gem "rack_middleware"
        gem "rack", "1.0.0", :force_version => true
      G

      expect(the_bundle).to include_gems("rack 1.0.0", "rack_middleware 1.0")
    end

    it "raises when forcing to an inexact version" do
      install_gemfile <<-G
        gem "rack", "> 1.0.0", :force_version => true
      G
      expect(out).to include("Cannot use force_version for inexact version requirement `> 1.0.0`.")
    end

    it "raises when forcing without specifying a version" do
      install_gemfile <<-G
        gem "rack", :force_version => true
      G
      expect(out).to include("Cannot use force_version for inexact version requirement `>= 0`.")
    end

    it "works when there's no conflict" do
      install_gemfile! <<-G
        source "file:#{gem_repo1}"
        gem "rack", "1.0.0", :force_version => true
      G

      expect(the_bundle).to include_gems("rack 1.0.0")
    end
  end

  context "with a complex conflict" do
    it "works" do
      install_gemfile! <<-G
        source "file:#{gem_repo1}"
        gem "rails", "2.3.2"
        gem "activesupport", "2.3.5", :force_version => true
      G

      expect(the_bundle).to include_gems("rails 2.3.2", "activesupport 2.3.5", "actionpack 2.3.2", "activerecord 2.3.2", "actionmailer 2.3.2", "activeresource 2.3.2")
    end
  end
end
