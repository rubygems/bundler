require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Bundler::Manifest" do

  def dep(name, options = {})
    Bundler::Dependency.new(name, options)
  end

  it "has a list of sources and dependencies" do
    sources = %w(http://gems.rubyforge.org)
    deps = []
    deps << dep("rails")
    deps << dep("will_paginate")
    
    manifest = Bundler::Manifest.new(sources, deps)
    manifest.sources.should == sources
    manifest.dependencies.should == deps
  end

  it "bundles itself (running all of the steps)" do
    pending
  end

end