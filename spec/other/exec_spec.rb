require File.expand_path('../../spec_helper', __FILE__)

describe "bundle exec" do
  before :each do
    system_gems "rack-1.0.0", "rack-0.9.1"
  end

  it "activates the correct gem" do
    gemfile <<-G
      gem "rack", "0.9.1"
    G

    bundle "exec rackup"
    out.should == "0.9.1"
  end

  it "works when the bins are in ~/.bundle" do
    install_gemfile <<-G
      gem "rack"
    G

    bundle "exec rackup"
    out.should == "1.0.0"
  end

  it "works when running from a random directory" do
    install_gemfile <<-G
      gem "rack"
    G

    bundle "exec cd #{tmp('gems')} && rackup"

    out.should == "1.0.0"
  end
end