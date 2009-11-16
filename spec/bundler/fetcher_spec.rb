require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Fetcher" do

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
      gem "very-simple"
    Gemfile
    m.install
    @log_output.should have_log_message("Updating source: file:#{gem_repo1}")
  end

  it "works with repositories that don't provide Marshal.4.8.Z" do
    FileUtils.cp_r gem_repo1, gem_repo2
    Dir["#{gem_repo2}/Marshal.*"].each { |f| File.unlink(f) }

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo2}"
      gem "rack"
    Gemfile

    tmp_gem_path.should have_cached_gems("rack-1.0.0")
  end

  it "works with repositories that don't provide prerelease_specs.4.8.gz" do
    FileUtils.cp_r gem_repo1, gem_repo2
    Dir["#{gem_repo2}/prerelease*"].each { |f| File.unlink(f) }

    install_manifest <<-Gemfile
      clear_sources
      source "file://#{gem_repo2}"
      gem "rack"
    Gemfile

    @log_output.should have_log_message("Source 'file:#{gem_repo2}' does not support prerelease gems")
    tmp_gem_path.should have_cached_gems("rack-1.0.0")
  end
end