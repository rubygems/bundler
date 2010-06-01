require "spec_helper"

describe "bundle install with gem sources" do
  describe "the simple case" do
    it "prints output and returns if no dependencies are specified" do
      gemfile <<-G
        source "file://#{gem_repo1}"
      G

      bundle :install
      out.should =~ /no dependencies/
    end

    it "fetches gems" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      default_bundle_path("gems/rack-1.0.0").should exist
      should_be_installed("rack 1.0.0")
    end

    it "pulls in dependencies" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rails"
      G

      should_be_installed "actionpack 2.3.2", "rails 2.3.2"
    end

    it "does the right version" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "0.9.1"
      G

      should_be_installed "rack 0.9.1"
    end

    it "does not install the development dependency" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "with_development_dependency"
      G

      should_be_installed "with_development_dependency 1.0.0"
      should_not_be_installed "activesupport 2.3.5"
    end

    it "resolves correctly" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activemerchant"
        gem "rails"
      G

      should_be_installed "activemerchant 1.0", "activesupport 2.3.2", "actionpack 2.3.2"
    end

    it "activates gem correctly according to the resolved gems" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport", "2.3.5"
      G

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activemerchant"
        gem "rails"
      G

      should_be_installed "activemerchant 1.0", "activesupport 2.3.2", "actionpack 2.3.2"
    end

    it "does not reinstall any gem that is already available locally" do
      system_gems "activesupport-2.3.2"

      build_repo2 do
        build_gem "activesupport", "2.3.2" do |s|
          s.write "lib/activesupport.rb", "ACTIVESUPPORT = 'fail'"
        end
      end

      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "activerecord", "2.3.2"
      G

      should_be_installed "activesupport 2.3.2"
    end

    it "works when the gemfile specifies gems that only exist in the system" do
      build_gem "foo", :to_system => true
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "foo"
      G

      should_be_installed "rack 1.0.0", "foo 1.0.0"
    end

    it "prioritizes local gems over remote gems" do
      build_gem 'rack', '1.0.0', :to_system => true do |s|
        s.add_dependency "activesupport", "2.3.5"
      end

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      should_be_installed "rack 1.0.0", "activesupport 2.3.5"
    end

    describe "with a gem that installs multiple platforms" do
      it "installs gems for the local platform as first choice" do
        install_gemfile <<-G
          Gem.platforms = [Gem::Platform.new('#{rb}'), Gem::Platform.local]
          source "file://#{gem_repo1}"
          gem "platform_specific"
        G

        run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
        out.should == "1.0.0 #{Gem::Platform.local}"
      end

      it "falls back on plain ruby" do
        install_gemfile <<-G
          Gem.platforms = [Gem::Platform.new('#{rb}'), Gem::Platform.new('#{linux}')]
          source "file://#{gem_repo1}"
          gem "platform_specific"
        G

        run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
        out.should == "1.0.0 RUBY"
      end

      it "installs gems for java" do
        install_gemfile <<-G
          Gem.platforms = [Gem::Platform.new('#{java}')]
          source "file://#{gem_repo1}"
          gem "platform_specific"
        G

        run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
        out.should == "1.0.0 JAVA"
      end

      it "installs gems for windows" do
        install_gemfile <<-G
          Gem.platforms = [Gem::Platform.new('#{mswin}')]
          source "file://#{gem_repo1}"
          gem "platform_specific"
        G

        run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
        out.should == "1.0.0 MSWIN"
      end
    end

    it "ensures that gems are actually installed and not just cached" do
      build_repo2
      gemfile <<-G
        source "file://#{gem_repo2}"
        group :foo do
          gem "rack"
        end
      G

      bundle "install --without foo"

      gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      update_repo gem_repo2 do
        build_gem "rack" do |s|
          s.write "lib/rack.rb", "raise 'omgomgomg'"
        end
      end

      bundle "install"
      should_be_installed "rack 1.0.0"
    end

    it "finds gems in multiple sources" do
      build_repo2
      update_repo2

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        source "file://#{gem_repo2}"

        gem "activesupport", "1.2.3"
        gem "rack", "1.2"
      G

      should_be_installed "rack 1.2", "activesupport 1.2.3"
    end

    it "gives a useful error if no sources are set" do
      install_gemfile <<-G
        gem "rack"
      G

      bundle :install, :expect_err => true
      out.should =~ /Your Gemfile doesn't have any sources/i
    end
  end

  describe "when prerelease gems are available" do
    it "finds prereleases" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "not_released"
      G
      should_be_installed "not_released 1.0.pre"
    end

    it "uses regular releases if available" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "has_prerelease"
      G
      should_be_installed "has_prerelease 1.0"
    end

    it "uses prereleases if requested" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "has_prerelease", "1.1.pre"
      G
      should_be_installed "has_prerelease 1.1.pre"
    end
  end

  describe "when prerelease gems are not available" do
    it "still works" do
      build_repo3
      install_gemfile <<-G
        source "file://#{gem_repo3}"
        gem "rack"
      G

      should_be_installed "rack 1.0"
    end
  end

  describe "when BUNDLE_PATH is set" do
    before :each do
      build_lib "rack", "1.0.0", :to_system => true do |s|
        s.write "lib/rack.rb", "raise 'FAIL'"
      end

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
    end

    it "installs gems to BUNDLE_PATH" do
      ENV['BUNDLE_PATH'] = bundled_app('vendor').to_s

      bundle :install

      bundled_app('vendor/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end

    it "installs gems to BUNDLE_PATH from .bundle/config" do
      config "BUNDLE_PATH" => bundled_app("vendor").to_s

      bundle :install

      bundled_app('vendor/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end

    it "installs gems to BUNDLE_PATH relative to root when relative" do
      ENV['BUNDLE_PATH'] = 'vendor'

      FileUtils.mkdir_p bundled_app('lol')
      Dir.chdir(bundled_app('lol')) do
        bundle :install
      end

      bundled_app('vendor/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end

    it "sets BUNDLE_PATH as the first argument to bundle install" do
      bundle "install ./vendor"

      bundled_app('vendor/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end

    it "disables system gems when passing a path to install" do
      # This is so that vendored gems can be distributed to others
      build_gem "rack", "1.1.0", :to_system => true
      bundle "install ./vendor"

      bundled_app('vendor/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end
  end

  describe "when passing in a Gemfile via --gemfile" do
    it "finds the gemfile" do
      gemfile bundled_app("NotGemfile"), <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      bundle :install, :gemfile => bundled_app("NotGemfile")

      ENV['BUNDLE_GEMFILE'] = "NotGemfile"
      should_be_installed "rack 1.0.0"
    end
  end

  describe "when disabling system gems" do
    before :each do
      build_gem "rack", "1.0.0", :to_system => true do |s|
        s.write "lib/rack.rb", "puts 'FAIL'"
      end
    end

    it "warns when using --disable-shared-gems when not specifying a bundle path"

    it "does not use available system gems" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "install vendor --disable-shared-gems"
      should_be_installed "rack 1.0.0"
    end

    it "remembers to disable system gems after the first time" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle "install vendor/gems --disable-shared-gems"
      FileUtils.rm_rf bundled_app('vendor/gems')
      bundle "install"

      bundled_app('vendor/gems/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end
  end

  describe "when loading only the default group" do
    it "should not load all groups" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activesupport", :group => :development
      G

      ruby <<-R
        require "bundler"
        Bundler.setup :default
        Bundler.require :default
        puts RACK
        begin
          require "activesupport"
        rescue LoadError
          puts "no activesupport"
        end
      R

      out.should include("1.0")
      out.should include("no activesupport")
    end
  end

  describe "when a gem has a YAML gemspec" do
    before :each do
      build_repo2 do
        build_gem "yaml_spec", :gemspec => :yaml
      end
    end

    it "still installs correctly" do
      gemfile <<-G
        source "file://#{gem_repo2}"
        gem "yaml_spec"
      G
      bundle :install
      err.should be_empty
    end
  end

  describe "when the gem has an architecture in its platform" do
    it "still installs correctly" do
      gemfile <<-G
        # Set up pretend http gem server with FakeWeb
        $LOAD_PATH.unshift '#{Dir[base_system_gems.join("gems/fakeweb*/lib")].first}'
        require 'fakeweb'
        FakeWeb.allow_net_connect = false
        files = [ 'specs.4.8.gz',
                  'prerelease_specs.4.8.gz',
                  'quick/Marshal.4.8/rcov-1.0-mswin32.gemspec.rz',
                  'gems/rcov-1.0-mswin32.gem' ]
        files.each do |file|
          FakeWeb.register_uri(:get, "http://localgemserver.com/\#{file}",
            :body => File.read("#{gem_repo1}/\#{file}"))
        end
        FakeWeb.register_uri(:get, "http://localgemserver.com/gems/rcov-1.0-x86-mswin32.gem",
          :status => ["404", "Not Found"])

        # Try to install gem with nil arch
        source "http://localgemserver.com/"
        Gem.platforms = [Gem::Platform.new('#{mswin}')]
        gem "rcov"
      G
      bundle :install
      should_be_installed "rcov 1.0.0"
    end
  end

  describe "bundler dependencies" do
    before(:each) do
      build_repo2 do
        build_gem "rails", "3.0" do |s|
          s.add_dependency "bundler", "~>0.9.0"
        end
        build_gem "bundler", "0.9.1"
        build_gem "bundler", Bundler::VERSION
      end
      ENV["BUNDLER_VERSION"] = "0.9.1"
    end

    after(:each) do
      ENV["BUNDLER_VERSION"] = nil
    end

    it "are forced to the current bundler version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
      G
      should_be_installed "bundler 0.9.1"
    end

    it "are not added if not already present" do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G
      should_not_be_installed "bundler 0.9.1"
    end

    it "cause a conflict if explicitly requesting a different version" do
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rails", "3.0"
        gem "bundler", "0.9.2"
      G
      out.should =~ /conflict on: "bundler"/i
    end
  end

  describe_sudo "it working when $GEM_HOME is owned by root" do
    it "installs gems" do
      pending "specs should never require user intervention. plus this passes even if it times out."
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem 'rack'
      G

      should_be_installed("rack 1.0.0")
    end
  end
end
