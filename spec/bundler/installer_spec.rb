require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Installing gems" do

  describe "the bundle directory" do

    before(:each) do
      @gems = %w(
        actionmailer-2.3.2 actionpack-2.3.2 activerecord-2.3.2
        activeresource-2.3.2 activesupport-2.3.2 rails-2.3.2 rake-0.8.7)
    end

    def setup
      @gems = %w(actionmailer-2.3.2 actionpack-2.3.2 activerecord-2.3.2
                 activeresource-2.3.2 activesupport-2.3.2 rails-2.3.2
                 rake-0.8.7)
      @manifest = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        gem "rails"
      Gemfile
    end

    it "creates the bundle directory if it does not exist" do
      setup
      @manifest.install
      bundled_app("vendor", "gems").should have_cached_gems(*@gems)
    end

    it "uses the bundle directory if it is empty" do
      bundled_app("vendor", "gems").mkdir_p
      setup
      @manifest.install
      bundled_app("vendor", "gems").should have_cached_gems(*@gems)
    end

    it "uses the bundle directory if it is a valid gem repo" do
      %w(cache doc gems specifications).each { |dir| bundled_app("vendor", "gems", dir).mkdir_p }
      bundled_app("vendor", "gems", "environment.rb").touch
      setup
      @manifest.install
      bundled_app("vendor", "gems").should have_cached_gems(*@gems)
    end

    it "does not use the bundle directory if it is not a valid gem repo" do
      bundled_app("vendor", "gems", "fail").touch_p
      lambda {
        setup
        @manifest.install
      }.should_not raise_error
    end

    it "installs the bins in the directory you specify" do
      bundled_app("omgbinz").mkdir_p
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"
        bin_path "#{bundled_app("omgbinz")}"
        gem "rails"
      Gemfile
      m.install
      bundled_app("omgbinz", "rails").should exist
    end

    it "does not remove any existing bin files" do
      bundled_app("bin").mkdir_p
      bundled_app("bin", "hello").touch
      setup
      @manifest.install
      bundled_app("bin", "hello").should exist
    end

    it "does not modify any .gemspec files that are to be installed if a directory of the same name exists" do
      dir  = bundled_app("gems", "rails-2.3.2")
      spec = bundled_app("specifications", "rails-2.3.2.gemspec")

      dir.mkdir_p
      spec.touch_p

      setup
      lambda { @manifest.install }.should_not change { [dir.mtime, spec.mtime] }
    end

    it "keeps bin files for already installed gems" do
      setup
      bundled_app("bin", "rails").should_not exist
      @manifest.install
      @manifest.install
      bundled_app("bin", "rails").should exist
    end

    it "does not remove bin files when updating gems" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      Gemfile

      tmp_bindir("rackup").should exist

      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo2}"
        gem "rack", "1.0.0"
      Gemfile

      tmp_bindir("rackup").should exist
    end

    it "each thing in the bundle has a directory in gems" do
      setup
      @manifest.install
      @gems.each do |name|
          bundled_app("vendor", "gems", "gems", name).should be_directory
      end
    end

    it "creates a specification for each gem" do
      setup
      @manifest.install
      @gems.each do |name|
        bundled_app("vendor", "gems", "specifications", "#{name}.gemspec").should be_file
      end
    end

    it "works with prerelease gems" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple-prerelease", "1.0.pre"
      Gemfile
      m.install
      bundled_app("vendor", "gems").should have_cached_gem("very-simple-prerelease-1.0.pre")
      bundled_app("vendor", "gems").should have_installed_gem("very-simple-prerelease-1.0.pre")
    end

    it "outputs a logger message for each gem that is installed" do
      setup
      @manifest.install
      @gems.each do |name|
        name, version = name.split("-")
        @log_output.should have_log_message("Installing #{name} (#{version})")
      end
    end

    it "copies gem executables to a specified path" do
      setup
      @manifest.install
      bundled_app('bin', 'rails').should be_file
    end

    it "compiles binary gems" do
      m = build_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo2}"
        gem "json"
      Gemfile
      m.install
      Dir["#{bundled_app}/vendor/gems/gems/json-*/**/*.#{Config::CONFIG['DLEXT']}"].should have_at_least(1).item
    end
  end
end
