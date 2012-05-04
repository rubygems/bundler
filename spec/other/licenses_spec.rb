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

    out.should include("actionpack: Unknown")
    out.should include("with_license: MIT")
  end
end
