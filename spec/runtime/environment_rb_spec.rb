require File.expand_path('../../spec_helper', __FILE__)

describe "environment.rb file" do
  it "does not pull in system gems" do
    system_gems "rack-1.0.0"

    install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "activesupport"
    G

    bundle :lock

    run <<-R, :lite_runtime => true
      require 'rubygems'
      begin;
        require 'rack'
      rescue LoadError
        puts 'WIN'
      end
    R

    out.should == "WIN"
  end
end
