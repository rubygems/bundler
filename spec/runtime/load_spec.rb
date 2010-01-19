require File.expand_path('../../spec_helper', __FILE__)

describe "Bubble.load" do

  before :each do
    in_app_root
    system_gems "rack-1.0.0"
  end

  it "provides a list of the env dependencies" do
    gemfile <<-G
      gem "rack"
    G

    env = Bubble.load
    env.dependencies.should have_dep("rack", ">= 0")
  end

  it "provides a list of the resolved gems" do
    pending
    gemfile <<-G
      gem "rack"
    G

    env = Bubble.load
    env.gems.should have_gem("rack-1.0.0")
  end

  it "raises an exception if the default gemfile is not found" do
    lambda {
      Bubble.load
    }.should raise_error(Bubble::GemfileNotFound, /default/)
  end

  it "raises an exception if a specified gemfile is not found" do
    lambda {
      Bubble.load("omg.rb")
    }.should raise_error(Bubble::GemfileNotFound, /omg\.rb/)
  end

  describe "when locked" do
    before :each do
      system_gems "rack-1.0.0", "activesupport-2.3.2", "activerecord-2.3.2", "activerecord-2.3.1"
    end

    it "raises an exception if the Gemfile adds a dependency" do
      gemfile <<-G
        gem "rack"
      G

      bbl :lock

      gemfile <<-G
        gem "rack"
        gem "activerecord"
      G

      lambda { Bubble.load }.should raise_error(Bubble::GemfileError)
    end

    it "raises an exception if the Gemfile removes a dependency" do
      gemfile <<-G
        gem "rack"
        gem "activerecord"
      G

      bbl :lock

      gemfile <<-G
        gem "rack"
      G

      lambda { Bubble.load }.should raise_error(Bubble::GemfileError)
    end

    it "raises an exception if the Gemfile changes a dependency in an incompatible way" do
      gemfile <<-G
        gem "rack"
        gem "activerecord"
      G

      bbl :lock

      gemfile <<-G
        gem "rack"
        gem "activerecord", "2.3.1"
      G

      lambda { Bubble.load }.should raise_error(Bubble::GemfileError)
    end

    it "raises an exception if the Gemfile replaces a root with a child dep of the root" do
      gemfile <<-G
        gem "rack"
        gem "activerecord"
      G

      bbl :lock

      gemfile <<-G
        gem "rack"
        gem "activesupport"
      G

      lambda { Bubble.load }.should raise_error(Bubble::GemfileError)
    end

    it "works if the Gemfile changes in a compatible way" do
      gemfile <<-G
        gem "rack"
        gem "activerecord", "2.3.2"
      G

      bbl :lock

      gemfile <<-G
        gem "rack"
        gem "activerecord", ">= 2.0.0"
      G

      lambda { Bubble.load }.should_not raise_error(Bubble::GemfileError)
    end
  end
end