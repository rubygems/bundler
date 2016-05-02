# frozen_string_literal: true
require "spec_helper"

describe "bundle check" do
  it "returns success when the gems.rb is satisfied" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check
    expect(exitstatus).to eq(0) if exitstatus
    expect(out).to include("gems.rb's dependencies are satisfied")
  end

  it "works with the --gemfile flag when not in the directory" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    Dir.chdir tmp
    bundle "check --gemfile bundled_app/gems.rb"
    expect(out).to include("gems.rb's dependencies are satisfied")
  end

  it "creates a gems.locked by default if one does not exist" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    FileUtils.rm("gems.locked")

    bundle "check"

    expect(bundled_app("gems.locked")).to exist
  end

  it "does not create a gems.locked if --dry-run was passed" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    FileUtils.rm("gems.locked")

    bundle "check --dry-run"

    expect(bundled_app("gems.locked")).not_to exist
  end

  it "prints a generic error if the missing gems are unresolvable" do
    system_gems ["rails-2.3.2"]

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check
    expect(err).to include("Bundler can't satisfy your gems.rb's dependencies.")
  end

  it "prints a generic error if a gems.locked does not exist and a toplevel dependency does not exist" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bundle :check
    expect(exitstatus).to be > 0 if exitstatus
    expect(err).to include("Bundler can't satisfy your gems.rb's dependencies.")
  end

  it "prints a generic message if you changed your lockfile" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rails'
    G
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rails_fail'
    G

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
      gem "rails_fail"
    G

    bundle :check
    expect(err).to include("Bundler can't satisfy your gems.rb's dependencies.")
  end

  it "remembers without option from config" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      group :foo do
        gem "rack"
      end
    G

    bundle "config without foo"
    bundle "install"
    bundle "check"
    expect(exitstatus).to eq(0) if exitstatus
    expect(out).to include("gems.rb's dependencies are satisfied")
  end

  it "ensures that gems are actually installed and not just cached" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", :group => :foo
    G

    bundle "config without foo"
    bundle "install"

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    bundle "check"
    expect(err).to include("* rack (1.0.0)")
    expect(exitstatus).to eq(1) if exitstatus
  end

  it "ignores missing gems restricted to other platforms" do
    system_gems "rack-1.0.0"

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      platforms :#{not_local_tag} do
        gem "activesupport"
      end
    G

    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          activesupport (2.3.5)
          rack (1.0.0)

      PLATFORMS
        #{local}
        #{not_local}

      DEPENDENCIES
        rack
        activesupport
    G

    bundle :check
    expect(out).to include("gems.rb's dependencies are satisfied")
  end

  it "works with env conditionals" do
    system_gems "rack-1.0.0"

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      env :NOT_GOING_TO_BE_SET do
        gem "activesupport"
      end
    G

    lockfile <<-G
      GEM
        remote: file:#{gem_repo1}/
        specs:
          activesupport (2.3.5)
          rack (1.0.0)

      PLATFORMS
        #{local}
        #{not_local}

      DEPENDENCIES
        rack
        activesupport
    G

    bundle :check
    expect(out).to include("gems.rb's dependencies are satisfied")
  end

  it "outputs an error when the default gems.rb is not found" do
    bundle :check
    expect(exitstatus).to eq(10) if exitstatus
    expect(err).to include("Could not locate gems.rb")
  end

  it "does not output fatal error message" do
    bundle :check
    expect(exitstatus).to eq(10) if exitstatus
    expect(err).not_to include("Unfortunately, a fatal error has occurred. ")
  end

  it "should not crash when called multiple times on a new machine" do
    gemfile <<-G
      gem 'rails', '3.0.0.beta3'
      gem 'paperclip', :git => 'git://github.com/thoughtbot/paperclip.git'
    G

    simulate_new_machine
    bundle :check, :expect_err => true
    last_out = out
    3.times do
      bundle :check, :expect_err => true
      expect(out).to eq(last_out)
      expect(err).to include("The git source git://github.com/thoughtbot/paperclip.git is not yet checked out. Please run `bundle install` before trying to start your application")
    end
  end

  context "bundle config path" do
    before do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
      G
      bundle "config path vendor/bundle"
      bundle "install"

      FileUtils.rm_rf(bundled_app(".bundle"))
    end

    it "returns success" do
      bundle "check"
      expect(exitstatus).to eq(0) if exitstatus
      expect(out).to include("gems.rb's dependencies are satisfied")
    end

    it "should write to .bundle/config" do
      bundle "check"
      bundle "check"
      expect(exitstatus).to eq(0) if exitstatus
    end
  end

  context "`config path vendor/bundle` after installing gems in the default directory" do
    it "returns false" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
      G

      bundle "config path vendor/bundle"
      bundle "check"
      expect(exitstatus).to eq(1) if exitstatus
      expect(err).to match(/The following gems are missing/)
    end
  end

  describe "when locked" do
    before :each do
      system_gems "rack-1.0.0"
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0"
      G
    end

    it "returns success when the gems.rb is satisfied" do
      bundle :install
      bundle :check
      expect(exitstatus).to eq(0) if exitstatus
      expect(out).to include("gems.rb's dependencies are satisfied")
    end

    it "shows what is missing with the current gems.rb if it is not satisfied" do
      simulate_new_machine
      bundle :check
      expect(err).to match(/The following gems are missing/)
      expect(err).to include("* rack (1.0")
    end
  end

  describe "BUNDLED WITH" do
    def lock_with(bundler_version = nil)
      lock = <<-L
        GEM
          remote: file:#{gem_repo1}/
          specs:
            rack (1.0.0)

        PLATFORMS
          #{generic_local_platform}

        DEPENDENCIES
          rack
      L

      if bundler_version
        lock += "\n        BUNDLED WITH\n           #{bundler_version}\n"
      end

      lock
    end

    before do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    context "is not present" do
      it "does not change the lock" do
        lockfile lock_with(nil)
        bundle :check
        lockfile_should_be lock_with(nil)
      end
    end

    context "is newer" do
      it "does not change the lock but warns" do
        lockfile lock_with(Bundler::VERSION.succ)
        bundle :check
        expect(out).to include("Bundler is older than the version that created the lockfile")
        expect(err).to lack_errors
        lockfile_should_be lock_with(Bundler::VERSION.succ)
      end
    end

    context "is older" do
      it "does not change the lock" do
        lockfile lock_with("1.10.1")
        bundle :check
        lockfile_should_be lock_with("1.10.1")
      end
    end
  end
end
