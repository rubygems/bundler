# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::Installer do
  subject(:installer) { Bundler::Plugin::Installer.new }

  describe "cli install" do
    it "raises error when non of the source is provided" do
      expect { installer.install("new-plugin", {}) }.
        to raise_error(ArgumentError)
    end

    describe "with mocked installers" do
      it "returns the installation path after installing git plugins" do
        allow(installer).to receive(:install_git).and_return("/git/install/path")

        expect(installer.install("new-plugin", :git => "https://some.ran/dom")).
          to eq("/git/install/path")
      end

      it "returns the installation path after installing rubygems plugins" do
        allow(installer).to receive(:install_rubygems).
          and_return("/rubygems/install/path")

        expect(installer.install("new-plugin", :source => "https://some.ran/dom")).
          to eq("/rubygems/install/path")
      end
    end

    describe "with actual installers" do
      it "returns the installation path after installing git plugins" do
        build_git "ga-plugin", :path => lib_path("ga-plugin") do |s|
          s.write "plugins.rb"
        end

        rev = revision_for(lib_path("ga-plugin"))
        expected_path = Bundler::Plugin.root.
          join("bundler", "gems", "ga-plugin-#{rev[0..11]}")

        opts = { :git => "file://#{lib_path("ga-plugin")}" }
        expect(installer.install("ga-plugin", opts)).
          to eq(expected_path)
      end

      it "returns the installation path after installing rubygems plugins" do
        build_repo2 do
          build_plugin "re-plugin"
        end

        opts = { :source => "file://#{gem_repo2}" }
        expect(installer.install("re-plugin", opts)).
          to eq(plugin_gems("re-plugin-1.0").to_s)
      end
    end
  end
end
