require File.expand_path('../../spec_helper', __FILE__)

describe "gemfile init" do
  before :each do
    in_app_root
  end

  it "generates a Gemfile" do
    bbl :init
    bundled_app("Gemfile").should exist
  end

  it "does not change existing Gemfiles" do
    gemfile <<-G
      gem "rails"
    G

    lambda {
      bbl :init
    }.should_not change { File.read(bundled_app("Gemfile")) }
  end
end