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

  it "should handle nested dependencies" do
    gemfile <<-G
      source "http://localgemserver.test"
      gem "rails"
    G

    bundle :install, :artifice => "endpoint"
    [
      "rails 2.3.2",
      "actionpack 2.3.2",
      "activerecord 2.3.2",
      "actionmailer 2.3.2",
      "activeresource 2.3.2",
      "activesupport 2.3.2"
    ].each {|gem| should_be_installed gem }
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

  it "falls back when hitting the Gemcutter Dependency Limit" do
    gemfile <<-G
      source "http://localgemserver.test"
      gem "activesupport"
      gem "actionpack"
      gem "actionmailer"
      gem "activeresource"
      gem "thin"
      gem "rack"
      gem "rails"
    G
    bundle :install, :artifice => "endpoint"

    [
      ["activesupport", "2.3.2"],
      ["actionpack", "2.3.2"],
      ["actionmailer", "2.3.2"],
      ["activeresource", "2.3.2"],
      ["activesupport", "2.3.2"],
      ["thin", "1.0.0"],
      ["rack", "1.0.0"],
      ["rails", "2.3.2"]
    ].each do |gem, version|
      should_be_installed "#{gem} #{version}"
    end
  end

  it "falls back when Gemcutter API doesn't return proper Marshal format" do
    gemfile <<-G
      source "http://localgemserver.test"
      gem "rack"
    G

    bundle :install, :artifice => "endpoint_marshal_fail"
    should_be_installed "rack 1.0.0"
  end
end
