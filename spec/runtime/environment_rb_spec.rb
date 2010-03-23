require File.expand_path('../../spec_helper', __FILE__)

describe "environment.rb file" do

  describe "with git gems that don't have gemspecs" do
    before :each do
      build_git "no-gemspec", :gemspec => false

      install_gemfile <<-G
        source "file://#{gem_repo1}"

        gem "no-gemspec", '1.0', :git => "#{lib_path('no-gemspec-1.0')}"
      G

      bundle :lock
    end

    it "works with gems from git that don't have gemspecs" do
      run <<-R, :lite_runtime => true
        `open '.bundle/environment.rb'`
        require 'no-gemspec'
        puts NOGEMSPEC
      R

      out.should == "1.0"
    end
  end

  describe "with bundled and system gems" do
    before :each do
      system_gems "rack-1.0.0"

      install_gemfile <<-G
        source "file://#{gem_repo1}"

        gem "activesupport", "2.3.5"
      G

      bundle :lock
    end

    it "does not pull in system gems" do
      run <<-R, :lite_runtime => true
        require 'rubygems'

        begin;
          require 'rack'
        rescue LoadError
          puts 'WIN'
        end
      R

      out.should == "WIN"
    end

    it "provides a gem method" do
      run <<-R, :lite_runtime => true
        gem 'activesupport'
        require 'activesupport'
        puts ACTIVESUPPORT
      R

      out.should == "2.3.5"
    end

    it "raises an exception if gem is used to invoke a system gem not in the bundle" do
      run <<-R, :lite_runtime => true
        begin
          gem 'rack'
        rescue LoadError => e
          puts e.message
        end
      R

      out.should == "rack is not part of the bundle. Add it to Gemfile."
    end

    it "sets GEM_HOME appropriately" do
      run "puts ENV['GEM_HOME']", :lite_runtime => true
      out.should == default_bundle_path.to_s
    end

    it "sets GEM_PATH appropriately" do
      run "puts Gem.path", :lite_runtime => true
      out.should == default_bundle_path.to_s
    end
  end

  describe "with system gems in the bundle" do
    before :each do
      system_gems "rack-1.0.0"

      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack", "1.0.0"
        gem "activesupport", "2.3.5"
      G

      bundle :lock
    end

    it "sets GEM_PATH appropriately" do
      run "puts Gem.path", :lite_runtime => true
      paths = out.split("\n")
      paths.should include(system_gem_path.to_s)
      paths.should include(default_bundle_path.to_s)
    end
  end

  describe "with a gemspec that requires other files" do
    before(:each) do
      build_git "bar", :gemspec => false do |s|
        s.write "lib/bar/version.rb", %{BAR_VERSION = '1.0'}
        s.write "bar.gemspec", <<-G
          require 'lib/bar/version'
          Gem::Specification.new do |s|
            s.name        = 'bar'
            s.version     = BAR_VERSION
            s.summary     = 'Bar'
            s.files       = Dir["lib/**/*.rb"]
          end
        G
      end

      install_gemfile <<-G
        gem "bar", :git => "#{lib_path('bar-1.0')}"
      G
      bundle :lock
    end

    it "evals each gemspec in the context of its parent directory" do

      run <<-R, :lite_runtime => true
        require 'bar'
        puts BAR
      R
      out.should == "1.0"
    end
  end

end
