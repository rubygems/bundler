require 'spec_helper'

describe "updating dependencies parallely", :realworld => true do
  before :each do
    install_gemfile <<-G
      source "https://rubygems.org"
      gem 'activesupport', '~> 3.2.12'
      gem 'faker', '~> 1.1.2'
    G
  end

  it "installs gems parallely" do
    gemfile <<-G
      source "https://rubygems.org"
      gem 'activesupport', '3.2.13'
      gem 'faker', '~> 1.1.2'
    G

    bundle :update, :jobs => 2, :env => {"DEBUG" => "1"}
    (0..1).each {|i| expect(out).to include("#{i}: ") }

    bundle "show activesupport"
    expect(out).to match(/activesupport-3\.2\.13/)

    bundle "show faker"
    expect(out).to match(/faker/)

    bundle "config jobs"
    expect(out).to match(/: "4"/)
  end
end
