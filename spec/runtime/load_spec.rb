require File.expand_path('../../spec_helper', __FILE__)

describe "Bundler.load" do

  before :each do
    system_gems "rack-1.0.0"
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
    env.gems.should have_gem("rack-1.0.0")
  end

  it "raises an exception if the default gemfile is not found" do
    lambda {
      Bundler.load
    }.should raise_error(Bundler::GemfileNotFound, /default/)
  end

  it "raises an exception if a specified gemfile is not found" do
    lambda {
      Bundler.load("omg.rb")
    }.should raise_error(Bundler::GemfileNotFound, /omg\.rb/)
  end

  describe "when locked" do
    before :each do
      pending
      system_gems "rack-1.0.0", "activesupport-2.3.2", "activerecord-2.3.2", "activerecord-2.3.1"
    end

    it "raises an exception if the Gemfile adds a dependency" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      bundle :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      lambda { Bundler.load }.should raise_error(Bundler::GemfileError)
    end

    it "raises an exception if the Gemfile removes a dependency" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      bundle :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      lambda { Bundler.load }.should raise_error(Bundler::GemfileError)
    end

    it "raises an exception if the Gemfile changes a dependency in an incompatible way" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      bundle :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord", "2.3.1"
      G

      lambda { Bundler.load }.should raise_error(Bundler::GemfileError)
    end

    it "raises an exception if the Gemfile replaces a root with a child dep of the root" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      bundle :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activesupport"
      G

      lambda { Bundler.load }.should raise_error(Bundler::GemfileError)
    end

    it "works if the Gemfile changes in a compatible way" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord", "2.3.2"
      G

      bundle :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord", ">= 2.0.0"
      G

      lambda { Bundler.load }.should_not raise_error(Bundler::GemfileError)
    end
  end

  describe "not hurting brittle rubygems" do
    before :each do
      system_gems ["activerecord-2.3.2", "activesupport-2.3.2"]
    end

    it "does not inject #source into the generated YAML of the gem specs" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "activerecord"
      G

      Bundler.load.specs.each do |spec|
        spec.to_yaml.should_not =~ /^\s+source:/
        spec.to_yaml.should_not =~ /^\s+groups:/
      end
    end
  end
end