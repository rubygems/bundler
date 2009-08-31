require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Getting gems from git" do

  describe "a simple gem in git" do
    before(:each) do
      @path = build_git_repo "very-simple", :with => fixture_dir.join("very-simple")
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple", "1.0", :git => "#{@path}"
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

    it "logs that the repo is being cloned" do
      @log_output.should have_log_message("Cloning git repository at: #{@path}")
    end
  end

  it "checks the root directory for a *.gemspec file" do
    spec = Gem::Specification.new do |s|
      s.name          = %q{very-simple}
      s.version       = "1.0"
      s.require_paths = ["lib"]
      s.add_dependency "rack", ">= 0.9.1"
    end
    @path = build_git_repo "very-simple", :with => fixture_dir.join("very-simple"), :spec => spec

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "very-simple", "1.0", :git => "#{@path}"
    Gemfile

    tmp_gem_path.should_not include_cached_gem("very-simple-1.0")
    tmp_gem_path.should include_cached_gem("rack-0.9.1")
    tmp_gem_path.should include_installed_gem("rack-0.9.1")
  end

  it "allows bundling a specific tag" do
    path = build_git_repo "very-simple", :with => fixture_dir.join("very-simple")
    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      gem "very-simple", "1.0", :git => "#{path}", :tag => 'tagz'
    Gemfile

    out = run_in_context "require 'very-simple/in_a_branch' ; puts OMG_IN_A_BRANCH"
    out.should == "tagged"
  end

end