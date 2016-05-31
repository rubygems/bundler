# frozen_string_literal: true
require "spec_helper"

describe "install with --deployment or --frozen" do
  before do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "fails without a lockfile and says that --deployment requires a lock" do
    bundle "install --deployment"
    expect(err).to include("The --deployment flag requires a gems.locked")
  end

  it "fails without a lockfile and says that --frozen requires a lock" do
    bundle "install --frozen"
    expect(err).to include("The --frozen flag requires a gems.locked")
  end

  it "works after you try to deploy without a lock" do
    bundle "install --deployment"
    bundle :install
    expect(exitstatus).to eq(0) if exitstatus
    should_be_installed "rack 1.0"
  end

  it "still works if you are not in the app directory and specify --gemfile" do
    bundle "install"
    Dir.chdir tmp
    simulate_new_machine

    bundle "install --gemfile #{tmp}/bundled_app/gems.rb --deployment"
    Dir.chdir bundled_app
    # See CLI::Install#run.
    with_config(:path => "#{Bundler.settings.path}/vendor/bundle") do
      should_be_installed "rack 1.0"
    end
  end

  it "works if you exclude a group with a git gem" do
    build_git "foo"
    gemfile <<-G
      group :test do
        gem "foo", :git => "#{lib_path("foo-1.0")}"
      end
    G
    bundle :install
    bundle "config without test"
    bundle "install --deployment"
    expect(exitstatus).to eq(0) if exitstatus
  end

  it "works when you bundle exec bundle" do
    bundle :install
    bundle "install --deployment"
    bundle "exec bundle check"
    expect(exitstatus).to eq(0) if exitstatus
  end

  it "works when using path gems from the same path and the version is specified" do
    build_lib "foo", :path => lib_path("nested/foo")
    build_lib "bar", :path => lib_path("nested/bar")
    gemfile <<-G
      gem "foo", "1.0", :path => "#{lib_path("nested")}"
      gem "bar", :path => "#{lib_path("nested")}"
    G

    bundle :install
    bundle "install --deployment"

    expect(exitstatus).to eq(0) if exitstatus
  end

  it "works when there are credentials in the source URL" do
    install_gemfile(<<-G, :artifice => "endpoint_strict_basic_authentication", :quiet => true)
      source "http://user:pass@localgemserver.test/"

      gem "rack-obama", ">= 1.0"
    G

    bundle "install --deployment", :artifice => "endpoint_strict_basic_authentication"

    expect(exitstatus).to eq(0) if exitstatus
  end

  it "works with sources given by a block" do
    install_gemfile <<-G
      source "file://#{gem_repo1}" do
        gem "rack"
      end
    G

    bundle "install --deployment"

    expect(exitstatus).to eq(0) if exitstatus
    should_be_installed "rack 1.0"
  end

  describe "with an existing lockfile" do
    before do
      bundle "install"
    end

    it "works with the --deployment flag if you didn't change anything" do
      bundle "install --deployment"
      expect(exitstatus).to eq(0) if exitstatus
    end

    it "works with the --frozen flag if you didn't change anything" do
      bundle "install --frozen"
      expect(exitstatus).to eq(0) if exitstatus
    end

    it "explodes with the --deployment flag if you make a change and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      bundle "install --deployment"
      expect(err).to include("deployment mode")
      expect(err).to include("You have added to gems.rb")
      expect(err).to include("* rack-obama")
      expect(out).not_to include("You have deleted from gems.rb")
      expect(out).not_to include("You have changed in gems.rb")
    end

    it "can have --frozen set via an environment variable" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      ENV["BUNDLE_FROZEN"] = "1"
      bundle "install"
      expect(err).to include("deployment mode")
      expect(err).to include("You have added to gems.rb")
      expect(err).to include("* rack-obama")
      expect(err).not_to include("You have deleted from gems.rb")
      expect(err).not_to include("You have changed in gems.rb")
    end

    it "can have --frozen set to false via an environment variable" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      ENV["BUNDLE_FROZEN"] = "false"
      bundle "install"
      expect(err).not_to include("deployment mode")
      expect(err).not_to include("You have added to gems.rb")
      expect(err).not_to include("* rack-obama")
    end

    it "explodes with the --frozen flag if you make a change and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "rack-obama"
      G

      bundle "install --frozen"
      expect(err).to include("deployment mode")
      expect(err).to include("You have added to gems.rb")
      expect(err).to include("* rack-obama")
      expect(err).not_to include("You have deleted from gems.rb")
      expect(err).not_to include("You have changed in gems.rb")
    end

    it "explodes if you remove a gem and don't check in the lockfile" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport"
      G

      bundle "install --deployment"
      expect(err).to include("deployment mode")
      expect(err).to include("You have added to gems.rb:\n* activesupport\n\n")
      expect(err).to include("You have deleted from gems.rb:\n* rack")
      expect(err).not_to include("You have changed in gems.rb")
    end

    it "explodes if you add a source" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", :git => "git://hubz.com"
      G

      bundle "install --deployment"
      expect(err).to include("deployment mode")
      expect(err).to include("You have added to gems.rb:\n* source: git://hubz.com (at master)")
      expect(err).not_to include("You have changed in gems.rb")
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

      bundle "install --deployment", :expect_err => true
      expect(err).to include("deployment mode")
      expect(err).to include("You have deleted from gems.rb:\n* source: #{lib_path("rack-1.0")} (at master@#{revision_for(lib_path("rack-1.0"))[0..6]}")
      expect(err).not_to include("You have added to gems.rb")
      expect(err).not_to include("You have changed in gems.rb")
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

      bundle "install --deployment", :expect_err => true
      expect(err).to include("deployment mode")
      expect(err).to include("You have changed in gems.rb:\n* rack from `no specified source` to `#{lib_path("rack")} (at master@#{revision_for(lib_path("rack"))[0..6]})`")
      expect(err).not_to include("You have added to gems.rb")
      expect(err).not_to include("You have deleted from gems.rb")
    end

    it "forgets that the bundle is frozen at runtime" do
      bundle "install --deployment"

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0"
        gem "rack-obama"
      G

      should_not_be_installed "rack 1.0.0"
    end
  end
end
