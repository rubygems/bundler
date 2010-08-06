require "spec_helper"

describe "Bundler.setup" do
  it "raises if the Gemfile was not yet installed" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    ruby <<-R
      require 'rubygems'
      require 'bundler'

      begin
        Bundler.setup
        puts "FAIL"
      rescue Bundler::GemNotFound
        puts "WIN"
      end
    R

    out.should == "WIN"
  end

  it "doesn't create a Gemfile.lock if the setup fails" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    ruby <<-R, :expect_err => true
      require 'rubygems'
      require 'bundler'

      Bundler.setup
    R

    bundled_app("Gemfile.lock").should_not exist
  end

  it "doesn't change the Gemfile.lock if the setup fails" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    lockfile = File.read(bundled_app("Gemfile.lock"))

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "nosuchgem", "10.0"
    G

    ruby <<-R, :expect_err => true
      require 'rubygems'
      require 'bundler'

      Bundler.setup
    R

    File.read(bundled_app("Gemfile.lock")).should == lockfile
  end

  it "makes a Gemfile.lock if setup succeeds" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    lockfile = File.read(bundled_app("Gemfile.lock"))

    FileUtils.rm(bundled_app("Gemfile.lock"))

    run "1"
    bundled_app("Gemfile.lock").should exist
  end

  it "uses BUNDLE_GEMFILE to locate the gemfile if present" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    gemfile bundled_app('4realz'), <<-G
      source "file://#{gem_repo1}"
      gem "activesupport", "2.3.5"
    G

    ENV['BUNDLE_GEMFILE'] = bundled_app('4realz').to_s
    bundle :install

    should_be_installed "activesupport 2.3.5"
  end

  it "prioritizes gems in BUNDLE_PATH over gems in GEM_HOME" do
    ENV['BUNDLE_PATH'] = bundled_app('.bundle').to_s
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", "1.0.0"
    G

    build_gem "rack", "1.0", :to_system => true do |s|
      s.write "lib/rack.rb", "RACK = 'FAIL'"
    end

    should_be_installed "rack 1.0.0"
  end

  describe "cripping rubygems" do
    describe "by replacing #gem" do
      before :each do
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack", "0.9.1"
        G
      end

      it "replaces #gem but raises when the gem is missing" do
        run <<-R
          begin
            gem "activesupport"
            puts "FAIL"
          rescue LoadError
            puts "WIN"
          end
        R

        out.should == "WIN"
      end

      it "replaces #gem but raises when the version is wrong" do
        run <<-R
          begin
            gem "rack", "1.0.0"
            puts "FAIL"
          rescue LoadError
            puts "WIN"
          end
        R

        out.should == "WIN"
      end
    end

    describe "by hiding system gems" do
      before :each do
        system_gems "activesupport-2.3.5"
        install_gemfile <<-G
          source "file://#{gem_repo1}"
          gem "yard"
        G
      end

      it "removes system gems from Gem.source_index" do
        run "require 'yard'"
        out.should == "bundler-#{Bundler::VERSION}\nyard-1.0"
      end
    end
  end

  describe "with paths" do
    it "activates the gems in the path source" do
      system_gems "rack-1.0.0"

      build_lib "rack", "1.0.0" do |s|
        s.write "lib/rack.rb", "puts 'WIN'"
      end

      gemfile <<-G
        path "#{lib_path('rack-1.0.0')}"
        source "file://#{gem_repo1}"
        gem "rack"
      G

      run "require 'rack'"
      out.should == "WIN"
    end
  end

  describe "with git" do
    before do
      build_git "rack", "1.0.0"

      gemfile <<-G
        gem "rack", :git => "#{lib_path('rack-1.0.0')}"
      G
    end

    it "provides a useful exception when the git repo is not checked out yet" do
      run "1", :expect_err => true
      err.should include("#{lib_path('rack-1.0.0')} (at master) is not checked out. Please run `bundle install`")
    end

    it "does not hit the git binary if the lockfile is available and up to date" do
      bundle "install"

      break_git!

      ruby <<-R
        require 'rubygems'
        require 'bundler'

        begin
          Bundler.setup
          puts "WIN"
        rescue Exception => e
          puts "FAIL"
        end
      R

      out.should == "WIN"
    end

    it "provides a good exception if the lockfile is unavailable" do
      bundle "install"

      FileUtils.rm(bundled_app("Gemfile.lock"))

      break_git!

      ruby <<-R
        require "rubygems"
        require "bundler"

        begin
          Bundler.setup
          puts "FAIL"
        rescue Bundler::GitError => e
          puts e.message
        end
      R

      run "puts 'FAIL'", :expect_err => true

      err.should_not include "This is not the git you are looking for"
    end

    it "works even when the cache directory has been deleted" do
      bundle "install vendor"
      FileUtils.rm_rf vendored_gems('cache')
      should_be_installed "rack 1.0.0"
    end

    it "does not randomly change the path when specifying --path and the bundle directory becomes read only" do
      begin
        bundle "install vendor"

        Dir["**/*"].each do |f|
          File.directory?(f) ?
            File.chmod(0555, f) :
            File.chmod(0444, f)
        end
        should_be_installed "rack 1.0.0"
      ensure
        Dir["**/*"].each do |f|
          File.directory?(f) ?
            File.chmod(0755, f) :
            File.chmod(0644, f)
        end
      end
    end
  end

  describe "when excluding groups" do
    it "doesn't change the resolve if --without is used" do
      install_gemfile <<-G, :without => :rails
        source "file://#{gem_repo1}"
        gem "activesupport"

        group :rails do
          gem "rails", "2.3.2"
        end
      G

      install_gems "activesupport-2.3.5"

      should_be_installed "activesupport 2.3.2", :groups => :default
    end

    it "remembers --without and does not bail on bare Bundler.setup" do
      install_gemfile <<-G, :without => :rails
        source "file://#{gem_repo1}"
        gem "activesupport"

        group :rails do
          gem "rails", "2.3.2"
        end
      G

      install_gems "activesupport-2.3.5"

      should_be_installed "activesupport 2.3.2"
    end

    it "remembers --without and does not include groups passed to Bundler.setup" do
      install_gemfile <<-G, :without => :rails
        source "file://#{gem_repo1}"
        gem "activesupport"

        group :rack do
          gem "rack"
        end

        group :rails do
          gem "rails", "2.3.2"
        end
      G

      should_not_be_installed "activesupport 2.3.2", :groups => :rack
      should_be_installed "rack 1.0.0", :groups => :rack
    end
  end

  # Unfortunately, gem_prelude does not record the information about
  # activated gems, so this test cannot work on 1.9 :(
  if RUBY_VERSION < "1.9"
    describe "preactivated gems" do
      it "raises an exception if a pre activated gem conflicts with the bundle" do
        system_gems "thin-1.0", "rack-1.0.0"
        build_gem "thin", "1.1", :to_system => true do |s|
          s.add_dependency "rack"
        end

        gemfile <<-G
          gem "thin", "1.0"
        G

        ruby <<-R
          require 'rubygems'
          gem "thin"
          require 'bundler'
          begin
            Bundler.setup
            puts "FAIL"
          rescue Gem::LoadError => e
            puts e.message
          end
        R

        out.should == "You have already activated thin 1.1, but your Gemfile requires thin 1.0. Consider using bundle exec."
      end
    end
  end

  # Rubygems returns loaded_from as a string
  it "has loaded_from as a string on all specs" do
    build_git "foo"
    build_git "no-gemspec", :gemspec => false

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
      gem "foo", :git => "#{lib_path('foo-1.0')}"
      gem "no-gemspec", "1.0", :git => "#{lib_path('no-gemspec-1.0')}"
    G

    run <<-R
      Gem.loaded_specs.each do |n, s|
        puts "FAIL" unless String === s.loaded_from
      end
    R

    out.should be_empty
  end

  it "ignores empty gem paths" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    ENV["GEM_HOME"] = ""
    bundle %{exec ruby -e "require 'set'"}

    err.should be_empty
  end

  it "should prepend gemspec require paths to $LOAD_PATH in order" do
    update_repo2 do
      build_gem("requirepaths") do |s|
        s.write("lib/rq.rb", "puts 'yay'")
        s.write("src/rq.rb", "puts 'nooo'")
        s.require_paths = ["lib", "src"]
      end
    end

    install_gemfile <<-G
      source "file://#{gem_repo2}"
      gem "requirepaths", :require => nil
    G

    run "require 'rq'"
    out.should == "yay"
  end

  it "ignores Gem.refresh" do
    system_gems "rack-1.0.0"

    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "activesupport"
    G

    run <<-R
      Gem.refresh
      puts Gem.source_index.find_name("rack").inspect
    R

    out.should == "[]"
  end
end
