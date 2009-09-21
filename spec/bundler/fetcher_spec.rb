require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Fetcher" do
  before(:each) do
    @source = Bundler::GemSource.new(:uri => "file://#{gem_repo1}")
    @other  = Bundler::GemSource.new(:uri => "file://#{gem_repo2}")
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

  it "does not include gems that don't match the current platform" do
    pending "Need to update the fixtures for this"
    begin
      Gem.platforms = [Gem::Platform::RUBY]
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "do_sqlite3"
      Gemfile

      m.install
      bundled_app.should have_cached_gems("do_sqlite3-0.9.11")

      # Try out windows
      # Gem.platforms = [Gem::Platform.new("mswin32_60")]
      # finder = Bundler::Finder.new(Bundler::GemSource.new(:uri => "file://#{gem_repo1}"))
      # finder.search(build_dep("do_sqlite3", "> 0")).should only_have_specs("do_sqlite3-0.9.12-x86-mswin32-60")
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

  it "works with repositories that don't provide Marshal.4.8.Z" do
    gem_repo1.cp_r(tmp_path.join('bogus_repo'))
    Dir["#{tmp_path.join('bogus_repo')}/Marshal.*"].each { |f| File.unlink(f) }

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{tmp_path.join('bogus_repo')}"
      gem "rack"
    Gemfile

    bundled_app.should have_cached_gems("rack-0.9.1")
  end
end