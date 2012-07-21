require "spec_helper"

describe "bundle open" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G
  end

  it "opens the gem with BUNDLER_EDITOR as highest priority" do
    bundle "open rails", :env => {"EDITOR" => "echo editor", "VISUAL" => "echo visual", "BUNDLER_EDITOR" => "echo bundler_editor"}
    out.should == "bundler_editor #{default_bundle_path('gems', 'rails-2.3.2')}"
  end

  it "opens the gem with VISUAL as 2nd highest priority" do
    bundle "open rails", :env => {"EDITOR" => "echo editor", "VISUAL" => "echo visual", "BUNDLER_EDITOR" => ""}
    out.should == "visual #{default_bundle_path('gems', 'rails-2.3.2')}"
  end

  it "opens the gem with EDITOR as 3rd highest priority" do
    bundle "open rails", :env => {"EDITOR" => "echo editor", "VISUAL" => "", "BUNDLER_EDITOR" => ""}
    out.should == "editor #{default_bundle_path('gems', 'rails-2.3.2')}"
  end

  it "complains if no EDITOR is set" do
    bundle "open rails", :env => {"EDITOR" => "", "VISUAL" => "", "BUNDLER_EDITOR" => ""}
    out.should == "To open a bundled gem, set $EDITOR or $BUNDLER_EDITOR"
  end

  it "complains if gem not in bundle" do
    bundle "open missing", :env => {"EDITOR" => "echo editor", "VISUAL" => "", "BUNDLER_EDITOR" => ""}
    out.should match(/could not find gem 'missing'/i)
  end

  it "opens the gem with short words" do
    bundle "open rec" , :env => {"EDITOR" => "echo editor", "VISUAL" => "echo visual", "BUNDLER_EDITOR" => "echo bundler_editor"}

    out.should == "bundler_editor #{default_bundle_path('gems', 'activerecord-2.3.2')}"
  end

  it "select the gem from many match gems" do
    env = {"EDITOR" => "echo editor", "VISUAL" => "echo visual", "BUNDLER_EDITOR" => "echo bundler_editor"}
    bundle "open active" , :env => env do |input|
      input.puts '2'
    end

    out.should =~ /bundler_editor #{default_bundle_path('gems', 'activerecord-2.3.2')}\z/
  end
end
