# frozen_string_literal: true
require "spec_helper"

context "when installing a bundle that includes yanked gems" do
  before(:each) do
    build_repo4 do
      build_gem "foo", "9.0.0"
    end
  end

  it "throws an error when the original gem version is yanked" do
    lockfile <<-L
       GEM
         remote: file://#{gem_repo4}
         specs:
           foo (10.0.0)

       PLATFORMS
         ruby

       DEPENDENCIES
         foo (= 10.0.0)

    L

    install_gemfile <<-G
        source "file://#{gem_repo4}"
        gem "foo", "10.0.0"
    G

    expect(out).to include("Your bundle is locked to foo (10.0.0)")
  end

  it "throws the original error when only the Gemfile specifies a gem version that doesn't exist" do
    install_gemfile <<-G
        source "file://#{gem_repo4}"
        gem "foo", "10.0.0"
    G

    expect(out).not_to include("Your bundle is locked to foo (10.0.0)")
    expect(out).to include("Could not find gem 'foo (= 10.0.0)' in any of the gem sources")
  end
end
