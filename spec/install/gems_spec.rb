require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile install with gem sources" do
  before :each do
    in_app_root
  end

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

  it "installs gems for the correct platform" do
    Gem.platforms = [rb]
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "platform_specific"
    G

    run "require 'platform_specific' ; puts PLATFORM_SPECIFIC"
    out.should == '1.0.0 RUBY'
  end

  describe "with extra sources" do

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

  end

  describe "when locked" do
    it "works" do
      system_gems "rack-1.0.0" do
        gemfile <<-G
          source "file://#{gem_repo1}"
          gem "rack"
        G

        bundle :lock
      end

      system_gems [] do
        bundle :install
        should_be_installed "rack 1.0.0"
      end
    end
  end

  describe "with BUNDLE_PATH set" do
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

    it "installs gems to BUNDLE_PATH from .bundleconfig" do
      pending
      config "BUNDLE_PATH" => bundled_app("vendor").to_s

      bundle :install

      bundled_app('vendor/gems/rack-1.0.0').should be_directory
      should_be_installed "rack 1.0.0"
    end
  end

  describe "when packed and locked" do
    it "does not hit the remote at all" do
      build_repo2
      install_gemfile <<-G
        source "file://#{gem_repo2}"
        gem "rack"
      G

      bundle :lock
      bundle :pack

      system_gems []
      FileUtils.rm_rf gem_repo2

      bundle :install
      should_be_installed "rack 1.0.0"
    end
  end

  describe "when specifying groups not excluded" do
    before :each do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        group :emo do
          gem "activesupport", "2.3.5"
        end
      G
    end

    it "installs gems in the default group" do
      out = ruby <<-G
        begin ; require 'rubygems' ; require 'rack' ; puts "WIN" ; end
      G
      out.should == "WIN"
    end

    it "installs gems in other groups" do
      out = ruby <<-G
        begin ; require 'rubygems' ; require 'activesupport' ; puts "WIN" ; end
      G
      out.should == "WIN"
    end

    it "sets up everything if Bundler.setup is used with no groups" do
      out = run("require 'rack'; puts RACK")
      out.should == '1.0.0'

      out = run("require 'activesupport'; puts ACTIVESUPPORT")
      out.should == '2.3.5'
    end
  end

  describe "when excluding groups" do
    before :each do
      install_gemfile <<-G, 'without' => 'emo'
        source "file://#{gem_repo1}"
        gem "rack"
        group :emo do
          gem "activesupport", "2.3.5"
        end
      G
    end

    it "installs gems in the default group" do
      out = ruby <<-G
        begin ; require 'rubygems' ; require 'rack' ; puts "WIN" ; end
      G
      out.should == "WIN"
    end

    it "does not install gems from the excluded group" do
      out = ruby <<-G
        begin ; require 'rubygems' ; require 'activesupport'
        rescue LoadError
          puts "WIN"
        end
      G

      out.should == 'WIN'
    end

    it "allows Bundler.setup for specific groups" do
      out = run("require 'rack'; puts RACK", :default)
      out.should == '1.0.0'
    end
  end
end