require "spec_helper"

describe "install with --deployment" do
  before do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "fails without a lockfile" do
    bundle "install --deployment"
    out.should include("The --deployment flag requires a Gemfile.lock")
  end

  describe "with an existing lockfile" do
    before do
      bundle "install"
    end

    it "works if you didn't change anything" do
      bundle "install --deployment", :exit_status => true
      exitstatus.should == 0
    end

    it "explodes if you make a change and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      bundle "install --deployment"
      out.should include("You have modified your Gemfile")
      out.should include("You have added to the Gemfile")
      out.should include("* rack-obama")
      out.should_not include("You have deleted from the Gemfile")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you remove a gem and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport"
      G

      bundle "install --deployment"
      out.should include("You have modified your Gemfile")
      out.should include("You have added to the Gemfile:\n* activesupport\n\n")
      out.should include("You have deleted from the Gemfile:\n* rack")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you add a source" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "git://hubz.com"
      G

      bundle "install --deployment"
      out.should include("You have modified your Gemfile")
      out.should include("You have added to the Gemfile:\n* source: git://hubz.com (at master)")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you unpin a source" do
      build_git "rack"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path("rack-1.0")}"
      G

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "install --deployment"
      out.should include("You have modified your Gemfile")
      out.should include("You have deleted from the Gemfile:\n* source: #{lib_path("rack-1.0")} (at master)")
      out.should_not include("You have added to the Gemfile")
      out.should_not include("You have changed in the Gemfile")
    end

    it "explodes if you unpin a source, leaving it pinned somewhere else" do
      build_lib "foo", :path => lib_path("rack/foo")
      build_git "rack", :path => lib_path("rack")

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "#{lib_path("rack")}"
        gem "foo", :git => "#{lib_path("rack")}"
      G

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "foo", :git => "#{lib_path("rack")}"
      G

      bundle "install --deployment"
      out.should include("You have modified your Gemfile")
      out.should include("You have changed in the Gemfile:\n* rack from `no specified source` to `#{lib_path("rack")} (at master)`")
      out.should_not include("You have added to the Gemfile")
      out.should_not include("You have deleted from the Gemfile")
    end
  end
end
