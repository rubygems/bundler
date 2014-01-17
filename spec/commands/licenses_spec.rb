require "spec_helper"

describe "bundle licenses" do
  before :each do
    install_gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
      gem "with_license"
    G
  end

  it "prints license information for all gems in the bundle" do
    bundle "licenses"

    expect(out).to include("actionpack: Unknown")
    expect(out).to include("with_license: MIT")
  end

  it "performs an automatic bundle install" do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rails"
      gem "with_license"
      gem "foo"
    G

    bundle :licenses, :env => { 'BUNDLE_INSTALL' => '1' }
    expect(out).to include("Installing foo 1.0")
  end
end
