# frozen_string_literal: true
require "spec_helper"

describe "bundler plugin install" do
  before do
    build_repo2 do
      build_plugin "foo"
      build_plugin "kung-foo"
    end
  end

  it "shows propper message when gem in not found in the source" do
    bundle "plugin install no-foo --source file://#{gem_repo1}"

    expect(out).to include("Could not find")
    plugin_should_not_be_installed("no-foo")
  end

  it "installs from rubygems source" do
    bundle "plugin install foo --source file://#{gem_repo2}"

    expect(out).to include("Installed plugin foo")
    plugin_should_be_installed("foo")
  end

  it "installs multiple plugins" do
    bundle "plugin install foo kung-foo --source file://#{gem_repo2}"

    expect(out).to include("Installed plugin foo")
    expect(out).to include("Installed plugin kung-foo")

    plugin_should_be_installed("foo", "kung-foo")
  end

  it "uses the same version for multiple plugins" do
    update_repo2 do
      build_plugin "foo", "1.1"
      build_plugin "kung-foo", "1.1"
    end

    bundle "plugin install foo kung-foo --version '1.0' --source file://#{gem_repo2}"

    expect(out).to include("Installing foo 1.0")
    expect(out).to include("Installing kung-foo 1.0")
    plugin_should_be_installed("foo", "kung-foo")
  end

  context "malformatted plugin" do
    it "fails when plugins.rb is missing" do
      build_repo2 do
        build_gem "charlie"
      end

      bundle "plugin install charlie --source file://#{gem_repo2}"

      expect(out).to include("plugins.rb was not found")

      expect(plugin_gems("charlie-1.0")).not_to be_directory

      plugin_should_not_be_installed("charlie")
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

      expect(plugin_gems("chaplin-1.0")).not_to be_directory

      plugin_should_not_be_installed("chaplin")
    end
  end

  context "git plugins" do
    it "installs form a git source" do
      build_git "foo" do |s|
        s.write "plugins.rb"
      end

      bundle "plugin install foo --git file://#{lib_path("foo-1.0")}"

      expect(out).to include("Installed plugin foo")
      plugin_should_be_installed("foo")
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
      plugin_should_be_installed("foo")
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

      plugin_should_be_installed("foo")

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
      plugin_should_be_installed("ga-plugin")
    end
  end

  context "inline gemfiles" do
    it "installs the listed plugins" do
      code = <<-RUBY
        require "bundler/inline"

        gemfile do
          source 'file://#{gem_repo2}'
          plugin 'foo'
        end
      RUBY

      ruby code
      plugin_should_be_installed("foo")
    end
  end
end
