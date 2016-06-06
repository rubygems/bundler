# frozen_string_literal: true
require "spec_helper"

describe "bundler plugin install" do
  before do
    build_repo2 do
      build_plugin "foo"
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

  context "malformatted plugin" do
    it "fails when plugins.rb is missing" do
      build_repo2 do
        build_gem "charlie"
      end

      bundle "plugin install charlie --source file://#{gem_repo2}"

      expect(out).to include("plugins.rb was not found")

      expect(out).not_to include("Installed plugin")

      expect(plugin_gems("charlie-1.0")).not_to be_directory
    end

    it "fails when plugins.rb throws exception on load" do
      build_repo2 do
        build_plugin "chaplin" do |s|
          s.write "plugins.rb", <<-RUBY
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
        s.write "plugins.rb"
      end

      bundle "plugin install foo --git file://#{lib_path("foo-1.0")}"

      expect(out).to include("Installed plugin foo")
    end
  end

  context "Gemfile eval" do
    it "installs plugins listed in gemfile" do
      gemfile <<-G
        source 'file://#{gem_repo2}'
        plugin 'foo'
        gem 'rack', "1.0.0"
      G

      bundle "install"

      expect(out).to include("Installed plugin foo")

      expect(out).to include("Bundle complete!")

      should_be_installed("rack 1.0.0")
    end

    it "accepts plugin version" do
      update_repo2 do
        build_plugin "foo", "1.1.0"
      end

      install_gemfile <<-G
        source 'file://#{gem_repo2}'
        plugin 'foo', "1.0"
      G

      bundle "install"

      expect(out).to include("Installing foo 1.0")

      expect(out).to include("Installed plugin foo")

      expect(out).to include("Bundle complete!")
    end

    it "accepts git sources" do
      build_git "ga-plugin" do |s|
        s.write "plugins.rb"
      end

      install_gemfile <<-G
        plugin 'ga-plugin', :git => "#{lib_path("ga-plugin-1.0")}"
      G

      expect(out).to include("Installed plugin ga-plugin")
    end
  end
end
