require "spec_helper"

describe "environment.rb file" do

  describe "with git gems that don't have gemspecs" do
    before :each do
      build_git "no-gemspec", :gemspec => false

      install_gemfile <<-G
        gem "no-gemspec", "1.0", :git => "#{lib_path('no-gemspec-1.0')}"
      G

      bundle :lock
    end

    it "loads the library via a virtual spec" do
      run <<-R, :lite_runtime => true
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
    before :each do
      build_git "bar", :gemspec => false do |s|
        s.write "lib/bar/version.rb", %{BAR_VERSION = '1.0'}
        s.write "bar.gemspec", <<-G
          lib = File.expand_path('../lib/', __FILE__)
          $:.unshift lib unless $:.include?(lib)
          require 'bar/version'

          Gem::Specification.new do |s|
            s.name        = 'bar'
            s.version     = BAR_VERSION
            s.summary     = 'Bar'
            s.files       = Dir["lib/**/*.rb"]
          end
        G
      end

      gemfile <<-G
        gem "bar", :git => "#{lib_path('bar-1.0')}"
      G
    end

    it "evals each gemspec in the context of its parent directory" do
      bundle :install
      bundle :lock
      run "require 'bar'; puts BAR", :lite_runtime => true
      out.should == "1.0"
    end

    it "error intelligently if the gemspec has a LoadError" do
      update_git "bar", :gemspec => false do |s|
        s.write "bar.gemspec", "require 'foobarbaz'"
      end
      bundle :install
      out.should include("was a LoadError while evaluating bar.gemspec")
      out.should include("foobarbaz")
      out.should include("bar.gemspec:1")
      out.should include("try to require a relative path") if RUBY_VERSION >= "1.9.0"
    end

    it "evals each gemspec with a binding from the top level" do
      bundle "install"

      ruby <<-RUBY
        require 'bundler'
        def Bundler.require(path)
          raise "LOSE"
        end
        Bundler.load
      RUBY

      err.should be_empty
      out.should be_empty
    end
  end

  describe "when Bundler is bundled" do
    it "doesn't blow up" do
      install_gemfile <<-G
        gem "bundler", :path => "#{File.expand_path("..", lib)}"
      G
      bundle :lock

      bundle %|exec ruby -e "require 'bundler'; Bundler.setup"|
      err.should be_empty
    end
  end
end
