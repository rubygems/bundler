require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile pack with gems" do
  before :each do
    gemfile <<-G
      gem 'rack'
    G

    system_gems "rack-1.0.0"
    bbl :pack
  end

  it "copies the .gem file to vendor/cache" do
    bundled_app("vendor/cache/rack-1.0.0.gem").should exist
  end

  it "uses the pack as a source when installing gems" do
    system_gems []
    bbl :install

    should_be_installed("rack 1.0.0")
  end
end