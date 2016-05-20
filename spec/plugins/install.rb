#frozen_string_literal: true
require 'spec_helper'

describe "bundler plugin install" do
  before do
    build_repo2 do
      build_gem "foo" do |s|
        s.write "plugin.rb"
      end
    end
  end

  it "fails when source in not provided" do
    bundle "plugin install foo"

    expect(out).to include("You need to provide the source")

    expect(out).not_to include("Installed plugin")
  end

  it "shows propper message when gem in not found in the source" do
    bundle "plugin install no-foo --source file://#{gem_repo1}"

    expect(out).to include("Could not find")
  end

  it "installs from rubygems source" do
    bundle "plugin install foo --source file://#{gem_repo2}"

    expect(out).to include("Installed plugin foo")
  end

  it "shows error for plugins with dependencies" do
    build_repo2 do
      build_gem "kung-foo" do |s|
        s.write "plugin.rb"
        s.add_dependency "rake"
      end
    end

    bundle "plugin install kung-foo --source file://#{gem_repo2}"
    
    expect(out).to include("Plugin dependencies are not supported")

    expect(out).not_to include("Installed plugin")
  end
end
