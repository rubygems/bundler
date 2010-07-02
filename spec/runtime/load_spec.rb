require "spec_helper"

describe "Bundler.load" do
  before :each do
    system_gems "rack-1.0.0"
    # clear memoized method results
    # TODO: Don't reset internal ivars
    Bundler.instance_eval do
      @load = nil
      @runtime = nil
      @definition = nil
    end
  end

  it "provides a list of the env dependencies" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    env = Bundler.load
    env.dependencies.should have_dep("rack", ">= 0")
  end

  it "provides a list of the resolved gems" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    env = Bundler.load
    env.gems.should have_gem("rack-1.0.0", "bundler-#{Bundler::VERSION}")
  end

  it "raises an exception if the default gemfile is not found" do
    lambda {
      Bundler.load
    }.should raise_error(Bundler::GemfileNotFound, /could not locate gemfile/i)
  end

  it "raises an exception if a specified gemfile is not found" do
    lambda {
      ENV['BUNDLE_GEMFILE'] = "omg.rb"
      Bundler.load
    }.should raise_error(Bundler::GemfileNotFound, /omg\.rb/)
  end

  describe "when called twice" do
    it "doesn't try to load the runtime twice" do
      system_gems "rack-1.0.0", "activesupport-2.3.5"
      gemfile <<-G
        gem "rack"
        gem "activesupport", :group => :test
      G

      ruby <<-RUBY
        require "bundler"
        Bundler.setup :default
        Bundler.require :default
        puts RACK
        begin
          require "activesupport"
        rescue LoadError
          puts "no activesupport"
        end
      RUBY

      out.split("\n").should == ["1.0.0", "no activesupport"]
    end
  end

  describe "when locked" do
    before :each do
      install_gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activesupport"
      G
      bundle :lock
    end

    # This is obviously not true on 1.9 thanks to the AWEOME! gem prelude :'(
    it "does not invoke setup inside env.rb" do
      ruby <<-RUBY
        require 'bundler'
        Bundler.load
        puts $LOAD_PATH.grep(/activesupport/i)
      RUBY

      out.should == ""
    end if RUBY_VERSION < "1.9"
  end

  describe "not hurting brittle rubygems" do
    it "does not inject #source into the generated YAML of the gem specs" do
      system_gems "activerecord-2.3.2", "activesupport-2.3.2"
      gemfile <<-G
        gem "activerecord"
      G

      Bundler.load.specs.each do |spec|
        spec.to_yaml.should_not =~ /^\s+source:/
        spec.to_yaml.should_not =~ /^\s+groups:/
      end
    end
  end

end
