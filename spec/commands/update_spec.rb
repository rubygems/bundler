# frozen_string_literal: true
require "spec_helper"

describe "bundle update" do
  before :each do
    build_repo2

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
      gem "rack-obama"
    G
  end

  describe "with no arguments" do
    it "updates the entire bundle" do
      update_repo2 do
        build_gem "activesupport", "3.0"
      end

      bundle "update"
      expect(out).to include("Bundle updated!")
      should_be_installed "rack 1.2", "rack-obama 1.0", "activesupport 3.0"
    end

    it "doesn't delete the gems.locked file if something goes wrong" do
      gemfile <<-G
        source "file://#{gem_repo2}"
        gem "activesupport"
        gem "rack-obama"
        exit!
      G
      bundle "update"
      expect(bundled_app("gems.locked")).to exist
    end
  end

  describe "--quiet argument" do
    it "hides UI messages" do
      bundle "update --quiet"
      expect(out).not_to include("Bundle updated!")
    end
  end

  describe "with a top level dependency" do
    it "unlocks all child dependencies that are unrelated to other locked dependencies" do
      update_repo2 do
        build_gem "activesupport", "3.0"
      end

      bundle "update rack-obama"
      should_be_installed "rack 1.2", "rack-obama 1.0", "activesupport 2.3.5"
    end
  end

  describe "with an unknown dependency" do
    it "should inform the user" do
      bundle "update halting-problem-solver", :expect_err => true
      expect(err).to include "Could not find gem 'halting-problem-solver'"
    end
    it "should suggest alternatives" do
      bundle "update active-support", :expect_err => true
      expect(err).to include "Did you mean activesupport?"
    end
  end

  describe "with a child dependency" do
    it "should update the child dependency" do
      update_repo2
      bundle "update rack"
      should_be_installed "rack 1.2"
    end
  end

  describe "with --local option" do
    it "doesn't hit repo2" do
      FileUtils.rm_rf(gem_repo2)

      bundle "update --local"
      expect(out).not_to match(/Fetching source index/)
    end
  end

  describe "with --group option" do
    it "should update only specifed group gems" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "activesupport", :group => :development
        gem "rack"
      G
      update_repo2 do
        build_gem "activesupport", "3.0"
      end
      bundle "update --group development"
      should_be_installed "activesupport 3.0"
      should_not_be_installed "rack 1.2"
    end

    context "when there is a source with the same name as a gem in a group" do
      before :each do
        build_git "foo", :path => lib_path("activesupport")
        install_gemfile <<-G
          source "file://#{gem_repo2}"
          gem "activesupport", :group => :development
          gem "foo", :git => "#{lib_path("activesupport")}"
        G
      end

      it "should not update the gems from that source" do
        update_repo2 { build_gem "activesupport", "3.0" }
        update_git "foo", "2.0", :path => lib_path("activesupport")

        bundle "update --group development"
        should_be_installed "activesupport 3.0"
        should_not_be_installed "foo 2.0"
      end
    end
  end
end

describe "bundle update in more complicated situations" do
  before :each do
    build_repo2
  end

  it "will eagerly unlock dependencies of a specified gem" do
    install_gemfile <<-G
      source "file://#{gem_repo2}"

      gem "thin"
      gem "rack-obama"
    G

    update_repo2 do
      build_gem "thin", "2.0" do |s|
        s.add_dependency "rack"
      end
    end

    bundle "update thin"
    should_be_installed "thin 2.0", "rack 1.2", "rack-obama 1.0"
  end
end

describe "bundle update without a gems.locked" do
  it "should not explode" do
    build_repo2

    gemfile <<-G
      source "file://#{gem_repo2}"

      gem "rack", "1.0"
    G

    bundle "update"

    should_be_installed "rack 1.0.0"
  end
end

describe "bundle update when a gem depends on a newer version of bundler" do
  before(:each) do
    build_repo2 do
      build_gem "rails", "3.0.1" do |s|
        s.add_dependency "bundler", Bundler::VERSION.succ
      end
    end

    gemfile <<-G
      source "file://#{gem_repo2}"
      gem "rails", "3.0.1"
    G
  end

  it "should explain that bundler conflicted" do
    bundle "update"
    expect(err).not_to match(/in snapshot/i)
    expect(out).to include("current bundler version")
    expect(out).to include("rails (3.0.1) has dependency bundler (= #{Bundler::VERSION.succ})")
  end
end

describe "bundle update" do
  it "shows the previous version of the gem when updated from rubygems source" do
    build_repo2

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
    G

    bundle "update --verbose"
    expect(out).to include("Using activesupport 2.3.5")

    update_repo2 do
      build_gem "activesupport", "3.0"
    end

    bundle "update"
    expect(out).to include("Installing activesupport 3.0 (was 2.3.5)")
  end

  it "shows error message when gems.locked is not preset and gem is specified" do
    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
    G

    bundle "update nonexisting"
    expect(err).to include("This Bundle hasn't been installed yet. Run `bundle install` to update and install the bundled gems.")
    expect(exitstatus).to eq(22) if exitstatus
  end

  it "shows the summary of the using gems" do
    build_repo2

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "activesupport"
    G

    bundle "update --verbose"
    expect(out).to include("Using activesupport 2.3.5")

    update_repo2 do
      build_gem "activesupport", "3.0"
    end

    bundle "update"
    expect(out).to include("Using 1 already installed gems")
  end
end

describe "bundle update --ruby" do
  before do
    install_gemfile <<-G, :expect_err => true
        ::RUBY_VERSION = '2.1.3'
        ::RUBY_PATCHLEVEL = 100
        ruby '~> 2.1.0'
    G
    bundle "update --ruby", :expect_err => true
  end

  context "when the Gemfile removes the ruby" do
    before do
      install_gemfile <<-G, :expect_err => true
          ::RUBY_VERSION = '2.1.4'
          ::RUBY_PATCHLEVEL = 222
      G
    end
    it "removes the Ruby from the Gemfile.lock" do
      bundle "update --ruby", :expect_err => true

      lockfile_should_be <<-L
       GEM
         specs:

       PLATFORMS
         ruby

       DEPENDENCIES

       BUNDLED WITH
          #{Bundler::VERSION}
      L
    end
  end

  context "when the Gemfile specified an updated Ruby version" do
    before do
      install_gemfile <<-G, :expect_err => true
          ::RUBY_VERSION = '2.1.4'
          ::RUBY_PATCHLEVEL = 222
          ruby '~> 2.1.0'
      G
    end
    it "updates the Gemfile.lock with the latest version" do
      bundle "update --ruby", :expect_err => true

      lockfile_should_be <<-L
       GEM
         specs:

       PLATFORMS
         ruby

       DEPENDENCIES

       RUBY VERSION
          ruby 2.1.4p222

       BUNDLED WITH
          #{Bundler::VERSION}
      L
    end
  end

  context "when a different Ruby is being used than has been versioned" do
    before do
      install_gemfile <<-G, :expect_err => true
          ::RUBY_VERSION = '2.2.2'
          ::RUBY_PATCHLEVEL = 505
          ruby '~> 2.1.0'
      G
    end
    it "shows a helpful error message" do
      bundle "update --ruby", :expect_err => true

      expect(out).to include("Your Ruby version is 2.2.2, but your Gemfile specified ~> 2.1.0")
    end
  end

  context "when updating Ruby version and Gemfile `ruby`" do
    before do
      install_gemfile <<-G, :expect_err => true
          ::RUBY_VERSION = '1.8.3'
          ::RUBY_PATCHLEVEL = 55
          ruby '~> 1.8.0'
      G
    end
    it "updates the Gemfile.lock with the latest version" do
      bundle "update --ruby", :expect_err => true

      lockfile_should_be <<-L
       GEM
         specs:

       PLATFORMS
         ruby

       DEPENDENCIES

       RUBY VERSION
          ruby 1.8.3p55

       BUNDLED WITH
          #{Bundler::VERSION}
      L
    end
  end
end
