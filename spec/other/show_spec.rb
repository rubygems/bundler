require File.expand_path('../../spec_helper', __FILE__)

describe "bundle show" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  it "prints path if gem exists in bundle" do
    bundle "show rails"
    out.should == default_bundle_path('gems', 'rails-2.3.2').to_s
  end

  it "complains if gem not in bundle" do
    bundle "show missing"
    out.should =~ /could not find gem 'missing'/i
  end
end
