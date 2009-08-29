require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Getting gems from git" do

  before(:each) do
    path = build_git_repo :very_simple, :with => fixture_dir.join("very-simple")
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "very-simple", "1.0", :git => "#{path}"
    Gemfile
  end

  it "does not download the gem" do
    tmp_gem_path.should_not include_cached_gem("very-simple-1.0")
    tmp_gem_path.should_not include_installed_gem("very-simple-1.0")
  end

  it "clones the git repository" do
    tmp_gem_path("dirs", "dirs", "very-simple").should be_directory
  end

  it "has very-simple in the load path" do
    out = run_in_context "require 'very-simple' ; puts VerySimpleForTests"
    out.should == "VerySimpleForTests"
  end

  it "removes the directory during cleanup" do
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
    Gemfile

    tmp_gem_path("dirs", "very-simple").should_not be_directory
  end
end