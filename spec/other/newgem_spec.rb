require "spec_helper"

describe "bundle gem" do
  it "generates a gem skeleton" do
    bundle 'gem test'
    bundled_app("test/Gemfile").should exist
    bundled_app("test/Rakefile").should exist
    bundled_app("test/lib/test.rb").should exist
    bundled_app("test/lib/test/version.rb").should exist
  end
end