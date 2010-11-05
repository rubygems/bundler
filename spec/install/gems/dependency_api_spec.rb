require "spec_helper"

describe "gemcutter's dependency API" do
  it "should use the API" do
    gemfile <<-G
      source "http://localgemserver.test"
      gem "rack"
    G

    bundle :install, :artifice => "endpoint"
    should_be_installed "rack 1.0.0"
  end

  it "falls back when the API errors out" do
    simulate_platform mswin

    gemfile <<-G
      source "http://localgemserver.test/"
      gem "rcov"
    G

    bundle :install, :fakeweb => "windows"
    should_be_installed "rcov 1.0.0"
  end
end
