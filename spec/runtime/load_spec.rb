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
end