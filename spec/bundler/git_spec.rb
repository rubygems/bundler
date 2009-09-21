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
      tmp_gem_path.should     include_installed_gem("very-simple-1.0")
      tmp_gem_path.should     include_vendored_dir("very-simple")
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

      pending "Gotta figure out how to implement this" do
        tmp_gem_path("dirs", "very-simple").should_not be_directory
      end
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

  it "recursively finds all gemspec files in a git repository" do
    lib_builder("first", "1.0", :path => tmp_path("gitz", "first"))
    lib_builder("second", "1.0", :path => tmp_path("gitz", "second")) do |s|
      s.add_dependency "first", ">= 0"
      s.write "lib/second.rb", "require 'first' ; SECOND = 'required'"
    end

    gitify(tmp_path("gitz"))

    install_manifest <<-Gemfile
      clear_sources
      gem "second", "1.0", :git => "#{tmp_path('gitz')}"
    Gemfile

    out = run_in_context <<-RUBY
      Bundler.require_env
      puts FIRST
      puts SECOND
    RUBY

    out.should == "required\nrequired"
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