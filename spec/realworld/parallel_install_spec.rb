require 'spec_helper'

describe "installing dependencies parallely", :realworld => true do
  it "installs gems parallely" do
    gemfile <<-G
      source "https://rubygems.org"

      gem 'rails'
    G

    bundle :install, :jobs => 4
    bundle "show rails"
    expect(out).to match(/rails/)

    bundle "show rack"
    expect(out).to match(/rack/)
  end
end
