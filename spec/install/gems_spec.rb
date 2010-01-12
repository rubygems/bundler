require File.expand_path('../../spec_helper', __FILE__)

describe "bbl install" do
  before :each do
    in_app_root
  end

  it "works" do
    gemfile <<-G
      gem "rack"
    G

    bbl :install
    run "require 'rack'; puts RACK"
    out.should == "1.0.0"
  end
end