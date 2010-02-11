require File.expand_path('../../spec_helper', __FILE__)

describe "bundle init" do
  it "generates a Gemfile" do
    bundle :init
    bundled_app("Gemfile").should exist
  end

  it "does not change existing Gemfiles" do
    gemfile <<-G
      gem "rails"
    G

    lambda {
      bundle :init
    }.should_not change { File.read(bundled_app("Gemfile")) }
  end
end