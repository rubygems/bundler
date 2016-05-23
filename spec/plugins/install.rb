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

    expect(plugin_gems("kung-foo-1.0")).not_to be_directory
  end

  context "malformatted plugin" do

    it "fails when plugin.rb is missing" do
      build_repo2 do
        build_gem "charlie"
      end

      bundle "plugin install charlie --source file://#{gem_repo2}"

      expect(out).to include("plugin.rb was not found")

      expect(out).not_to include("Installed plugin")

      expect(plugin_gems("charlie-1.0")).not_to be_directory
    end


    it "fails when plugin.rb throws exception on load" do
      build_repo2 do
        build_gem "chaplin" do |s|
          s.write "plugin.rb", <<-RUBY
            raise "I got you man"
          RUBY
        end
      end

      bundle "plugin install chaplin --source file://#{gem_repo2}"

      expect(out).not_to include("Installed plugin")

      expect(plugin_gems("chaplin-1.0")).not_to be_directory
    end

  end

  context "git plugins" do
    it "installs form a git source" do
      build_git "foo" do |s|
        s.write "plugin.rb"
      end

      bundle "plugin install foo --git file://#{lib_path("foo-1.0")}"

      expect(out).to include("Installed plugin foo")
    end
  end
end
