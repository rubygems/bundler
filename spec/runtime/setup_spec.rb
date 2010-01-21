require File.expand_path('../../spec_helper', __FILE__)

describe "Bubble.setup" do

  before :each do
    in_app_root
    system_gems "rack-1.0.0", "activesupport-2.3.2"
  end

  it "setups up load paths for requested gems" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    run 'require "rack" ; puts RACK'
    out.should == "1.0.0"
  end

  it "does not allow access to system gems not specified in the Gemfile" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G

    run <<-RUBY
      begin ; require "activesupport" ; rescue LoadError ; puts 'win' ; end
    RUBY

    out.should == "win"
  end
end