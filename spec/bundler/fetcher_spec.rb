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
    build_repo2
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

  describe "platforms" do
    after :each do
      Gem.platforms = nil
    end

    def rb  ; Gem::Platform::RUBY ; end
    def java  ; Gem::Platform.new [nil, "java", nil]      ; end
    def linux ; Gem::Platform.new ['x86', 'linux', nil] ; end

    it "installs the gem for the correct platform" do
      Gem.platforms = [rb]
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "platform_specific"
      Gemfile

      out = run_in_context "Bundler.require_env ; puts PLATFORM_SPECIFIC"
      out.should == "1.0.0 RUBY"
    end

    it "raises GemNotFound if no gem for correct platform exists" do
      Gem.platforms = [linux]
      lambda do
        install_manifest <<-Gemfile
          clear_sources
          source "file://#{gem_repo1}"
          gem "platform_specific"
        Gemfile
      end.should raise_error(Bundler::GemNotFound)
    end

    it "selects java one when both are available" do
      Gem.platforms = [rb, java]
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "platform_specific"
      Gemfile

      out = run_in_context "Bundler.require_env ; puts PLATFORM_SPECIFIC"
      out.should == "1.0.0 JAVA"
    end

    it "finds the java one when only Java is there" do
      Gem.platforms = [rb, java]

      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "only_java"
      Gemfile

      out = run_in_context "Bundler.require_env ; puts ONLY_JAVA"
      out.should == "1.0"
    end

    it "raises GemNotFound if no gem for corect platform exists when gem dependencies are tied to specific sources" do
      Gem.platforms = [rb]
      system_gems "platform_specific-1.0-java" do
        lambda do
          install_manifest <<-Gemfile
            clear_sources
            gem "platform_specific", :bundle => false
          Gemfile
        end.should raise_error(Bundler::GemNotFound)
      end
    end
  end
end