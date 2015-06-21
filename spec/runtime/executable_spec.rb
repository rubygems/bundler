require "spec_helper"

describe "Running bin/* commands" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack"
    G
  end

  it "does not generate bin stubs if the option was not specified" do
    bundle "install"

    expect(bundled_app("bin/rackup")).not_to exist
  end
end
