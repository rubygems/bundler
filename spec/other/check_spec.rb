require File.expand_path('../../spec_helper', __FILE__)

describe "bbl check" do
  before :each do
    in_app_root
  end

  it "returns success when the Gemfile is satisfied" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bbl :check
    out.should == "The Gemfile's dependencies are satisfied"
  end

  it "shows what is missing with the current Gemfile if it is not satisfied" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
    G

    bbl :check
    out.should =~ /rails \(>= 0, runtime\)/
  end

  it "provides debug information when there is a resolving problem" do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rails'
    G
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem 'rails_fail'
    G

    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
      gem "rails_fail"
    G

    bbl :check
    out.should include('Conflict on: "activesupport"')
  end

  it "outputs an error when the default Gemspec is not found" do
    bbl :check
    out.should == "The default Gemfile was not found"
  end
end