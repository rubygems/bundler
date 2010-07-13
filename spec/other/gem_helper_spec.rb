require "spec_helper"
require 'bundler/gem_helper'

describe "Bundler::GemHelper tasks" do
  it "interpolates the name when there is only one gemspec" do
    bundle 'gem test'
    app = bundled_app("test")
    helper = Bundler::GemHelper.new(app.to_s)
    helper.name.should == 'test'
  end

  it "should fail when there is no gemspec" do
    bundle 'gem test'
    app = bundled_app("test")
    FileUtils.rm(File.join(app.to_s, 'test.gemspec'))
    proc { Bundler::GemHelper.new(app.to_s) }.should raise_error(/Unable to determine name/)
  end
end