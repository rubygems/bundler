require File.expand_path('../../spec_helper', __FILE__)

describe "bundle open" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  it "opens the gem with VISUAL if set" do
    bundle "open rails", :env => {"EDITOR" => "echo editor", "VISUAL" => "echo visual"}
    out.should == "visual #{default_bundle_path('gems', 'rails-2.3.2')}"
  end

  it "opens the gem with EDITOR if set" do
    bundle "open rails", :env => {"EDITOR" => "echo editor", "VISUAL" => ''}
    out.should == "editor #{default_bundle_path('gems', 'rails-2.3.2')}"
  end

  it "complains if gem not in bundle" do
    bundle "open missing", :env => {"EDITOR" => "echo editor", "VISUAL" => ''}
    out.should match(/could not find gem 'missing'/i)
  end
end
