require File.expand_path('../../spec_helper', __FILE__)

describe "Gemfile.load" do

  before :each do
    in_app_root
    system_gems "rack-1.0.0"
  end

  it "provides a list of the env dependencies" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    env = Gemfile.load
    env.dependencies.should have_dep("rack", ">= 0")
  end

  it "provides a list of the resolved gems" do
    pending
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    env = Gemfile.load
    env.gems.should have_gem("rack-1.0.0")
  end

  it "raises an exception if the default gemfile is not found" do
    lambda {
      Gemfile.load
    }.should raise_error(Gemfile::GemfileNotFound, /default/)
  end

  it "raises an exception if a specified gemfile is not found" do
    lambda {
      Gemfile.load("omg.rb")
    }.should raise_error(Gemfile::GemfileNotFound, /omg\.rb/)
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

      bbl :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      lambda { Gemfile.load }.should raise_error(Gemfile::GemfileError)
    end

    it "raises an exception if the Gemfile removes a dependency" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      bbl :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
      G

      lambda { Gemfile.load }.should raise_error(Gemfile::GemfileError)
    end

    it "raises an exception if the Gemfile changes a dependency in an incompatible way" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      bbl :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord", "2.3.1"
      G

      lambda { Gemfile.load }.should raise_error(Gemfile::GemfileError)
    end

    it "raises an exception if the Gemfile replaces a root with a child dep of the root" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord"
      G

      bbl :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activesupport"
      G

      lambda { Gemfile.load }.should raise_error(Gemfile::GemfileError)
    end

    it "works if the Gemfile changes in a compatible way" do
      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord", "2.3.2"
      G

      bbl :lock

      gemfile <<-G
        source "file://#{gem_repo1}"
        gem "rack"
        gem "activerecord", ">= 2.0.0"
      G

      lambda { Gemfile.load }.should_not raise_error(Gemfile::GemfileError)
    end
  end
end