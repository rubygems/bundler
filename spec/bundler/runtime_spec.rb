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
        puts VERYSIMPLE
      RUBY

      out.should == "1.0"
    end

    it "correctly requires the specified files" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rspec", :require_as => %w(spec)
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env
        puts SPEC
      RUBY

      out.should == "1.2.7"
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

    it "does not raise an exception if the gem does not have a default file to require" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack-test"
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env ; puts "Hello"
      RUBY

      out.should == "Hello"
    end

    it "raises an error if an explicitly specified require does not exist" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "rack-test", :require_as => 'rack-test'
      Gemfile

      out = run_in_context <<-RUBY
        begin
          Bundler.require_env
        rescue LoadError => e
          puts e.message
        end
      RUBY

      out.should include("no such file to load -- rack-test")
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
        puts VERYSIMPLE
      RUBY

      out.should == "1.0"
    end

    it "only requires gems in the environments they are exclusive to" do
      install_manifest <<-Gemfile
        clear_sources
        source "file://#{gem_repo1}"
        gem "very-simple", :only => :bar
      Gemfile

      out = run_in_context <<-RUBY
        Bundler.require_env      ; puts defined?(VERYSIMPLE).inspect
        Bundler.require_env :foo ; puts defined?(VERYSIMPLE).inspect
        Bundler.require_env :bar ; puts defined?(VERYSIMPLE)
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
        Bundler.require_env :bar ; puts defined?(VERYSIMPLE).inspect
        Bundler.require_env :foo ; puts defined?(VERYSIMPLE)
      RUBY

      out.should == "nil\nconstant"

      out = run_in_context <<-RUBY
        Bundler.require_env ; puts defined?(VERYSIMPLE)
      RUBY

      out.should == "constant"
    end
  end

end