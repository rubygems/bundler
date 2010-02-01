require File.expand_path('../../spec_helper', __FILE__)

describe "bundle exec" do
  before :each do
    system_gems "rack-1.0.0", "rack-0.9.1"
  end

  it "should have specs" do
    pending "The paths isn't working right for some reason"
    gemfile <<-G
      gem "rack", "0.9.1"
    G

    bundle :exec, "rackup"
    out.should == "0.9.1"
  end
end