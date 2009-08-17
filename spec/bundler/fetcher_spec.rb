require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Fetcher" do
  before(:each) do
    @source = Bundler::Source.new("file://#{gem_repo1}")
    @other  = Bundler::Source.new("file://#{gem_repo2}")
    @finder = Bundler::Finder.new(@source, @other)
  end

  it "stashes the source in the returned gem specification" do
    @finder.search(Gem::Dependency.new("abstract", ">= 0")).first.source.should == @source
  end

  it "uses the first source that was passed in if multiple sources have the same gem" do
    @finder.search(build_dep("activerecord", "= 2.3.2")).first.source.should == @source
  end

  it "raises if the source does not exist" do
    m = build_manifest <<-Gemfile
      clear_sources
      source "file://not/a/gem/source"
      gem "foo"
    Gemfile
    lambda { m.install }.should raise_error(ArgumentError)
  end

  it "raises if the source is not available" do
    m = build_manifest <<-Gemfile
      clear_sources
      source "http://localhost"
      gem "foo"
    Gemfile
    lambda { m.install }.should raise_error(ArgumentError)
  end

  it "raises if the source is not a gem repository" do
    m = build_manifest <<-Gemfile
      clear_sources
      source "http://google.com/not/a/gem/location"
      gem "foo"
    Gemfile
    lambda { m.install }.should raise_error(ArgumentError)
  end

  it "accepts multiple source indexes" do
    @finder.search(Gem::Dependency.new("abstract", ">= 0")).size.should == 1
    @finder.search(Gem::Dependency.new("merb-core", ">= 0")).size.should == 2
  end

  it "does not include gems that don't match the current platform" do
    begin
      Gem.platforms = [Gem::Platform::RUBY]
      finder = Bundler::Finder.new(@source)
      finder.search(build_dep("do_sqlite3", "> 0")).should only_have_specs("do_sqlite3-0.9.11")

      # Try out windows
      Gem.platforms = [Gem::Platform.new("mswin32_60")]
      finder = Bundler::Finder.new(Bundler::Source.new("file://#{gem_repo1}"))
      finder.search(build_dep("do_sqlite3", "> 0")).should only_have_specs("do_sqlite3-0.9.12-x86-mswin32-60")
    ensure
      Gem.platforms = nil
    end
  end

  it "outputs a logger message when updating an index from source" do
    m = build_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo1}"
      source "file://#{gem_repo2}"
      gem "very-simple"
    Gemfile
    m.install
    @log_output.should have_log_message("Updating source: file:#{gem_repo1}")
    @log_output.should have_log_message("Updating source: file:#{gem_repo2}")
  end

end