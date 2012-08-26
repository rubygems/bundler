require 'spec_helper'

describe "bundle inject" do
  context "with a lockfile" do
    before :each do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    it "adds the injected gems to the gemfile" do
      bundled_app("Gemfile").read.should_not match(/rack-obama/)
      bundle "inject 'rack-obama' '> 0'"
      bundled_app("Gemfile").read.should match(/rack-obama/)
    end

    it "locks with the injected gems" do
      bundled_app("Gemfile.lock").read.should_not match(/rack-obama/)
      bundle "inject 'rack-obama' '> 0'"
      bundled_app("Gemfile.lock").read.should match(/rack-obama/)
    end
  end

  context "without a lockfile" do
    before :each do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    it "locks with the injected gems" do
      bundled_app("Gemfile.lock").should_not exist
      bundle "inject 'rack-obama' '> 0'"
      bundled_app("Gemfile.lock").read.should match(/rack-obama/)
    end
  end

  context "injected gems already in the Gemfile" do
    before :each do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    it "doesn't add existing gems" do
      bundle "inject 'rack' '> 0'"
      out.should match(/cannot specify the same gem twice/i)
    end
  end
end