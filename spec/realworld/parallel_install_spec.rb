require 'spec_helper'

describe "installing dependencies parallely", :realworld => true do
  it "installs gems parallely" do
    gemfile <<-G
      source "https://rubygems.org"
      gem 'activesupport', '~> 3.2.13'
      gem 'faker', '~> 1.1.2'
    G

    bundle :install, :jobs => 2, :env => {"DEBUG" => "1"}
    (0..1).each {|i| expect(out).to include("#{i}: ") }

    bundle "show activesupport"
    expect(out).to match(%r{gems/activesupport})

    bundle "show faker"
    expect(out).to match(/faker/)

    bundle "config jobs"
    expect(out).to match(/: "2"/)
  end

  it "installs even with circular dependency", :realworld => true do
    gemfile <<-G
      source 'https://rubygems.org'
      gem 'mongoid_auto_increment', "0.1.1"
    G

    bundle :install, :jobs => 2, :env => {"DEBUG" => "1"}
    (0..1).each {|i| expect(out).to include("#{i}: ") }

    bundle "show mongoid_auto_increment"
    expect(out).to match(%r{gems/mongoid_auto_increment})
  end
end
