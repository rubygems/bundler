require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler runtime" do

  describe "basic runtime options" do
    it "requires files for all gems" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple"
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env
        puts VerySimpleForTests
      RUBY

      out.should == "VerySimpleForTests"
    end

    it "correctly requires the specified files" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo2}"
        gem "actionpack", :require_as => %w(action_controller action_view)
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env
        puts "\#{ActionController} -- \#{ActionView}"
      RUBY

      out.should == "ActionController -- ActionView"
    end

    it "executes blocks at require time" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple" do
          puts "Requiring"
        end
      Gemfile

      out = run_in_context <<-RUBY
        puts "Before"
        Bundler.require_env
        puts "After"
      RUBY

      out.should == "Before\nRequiring\nAfter"
    end
  end

  describe "with environments" do
    it "requires specific environments" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple"
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env :test
        puts VerySimpleForTests
      RUBY

      out.should == "VerySimpleForTests"
    end

    it "only requires gems in the environments they are exclusive to" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple", :only => :bar
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env      ; puts defined?(VerySimpleForTests)
        Bundler.require_env :foo ; puts defined?(VerySimpleForTests)
        Bundler.require_env :bar ; puts defined?(VerySimpleForTests)
      RUBY

      out.should == "nil\nnil\nconstant"
    end

    it "does not require gems in environments that they are excluded from" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple", :except => :bar
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env :bar ; puts defined?(VerySimpleForTests)
        Bundler.require_env :foo ; puts defined?(VerySimpleForTests)
      RUBY

      out.should == "nil\nconstant"

      out = run_in_context <<-RUBY
        Bundler.require_env ; puts defined?(VerySimpleForTests)
      RUBY

      out.should == "constant"
    end
  end

end