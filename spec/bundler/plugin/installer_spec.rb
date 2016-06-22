# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::Installer do
  subject(:installer) { Bundler::Plugin::Installer.new }

  describe "cli install" do
    it "uses Gem.sources when non of the source is provided" do
      sources = double(:sources)
      allow(Bundler).to receive_message_chain("rubygems.sources") { sources }

      allow(installer).to receive(:install_rubygems).
        with("new-plugin", [">= 0"], sources).once

      installer.install("new-plugin", {})
    end

    describe "with mocked installers" do
      it "returns the installation path after installing git plugins" do
        allow(installer).to receive(:install_git).
          and_return("new-plugin" => "/git/install/path")

        expect(installer.install(["new-plugin"], :git => "https://some.ran/dom")).
          to eq("new-plugin" => "/git/install/path")
      end

      it "returns the installation path after installing rubygems plugins" do
        allow(installer).to receive(:install_rubygems).
          and_return("new-plugin" => "/rubygems/install/path")

        expect(installer.install(["new-plugin"], :source => "https://some.ran/dom")).
          to eq("new-plugin" => "/rubygems/install/path")
      end
    end

    describe "with actual installers" do
      before do
        build_repo2 do
          build_plugin "re-plugin"
          build_plugin "ma-plugin"
        end
      end

      it "returns the installation path after installing git plugins" do
        build_git "ga-plugin", :path => lib_path("ga-plugin") do |s|
          s.write "plugins.rb"
        end

        rev = revision_for(lib_path("ga-plugin"))
        expected = { "ga-plugin" => Bundler::Plugin.root.join("bundler", "gems", "ga-plugin-#{rev[0..11]}").to_s }

        opts = { :git => "file://#{lib_path("ga-plugin")}" }
        expect(installer.install(["ga-plugin"], opts)).to include(expected)
      end

      it "returns the installation path after installing rubygems plugins" do
        opts = { :source => "file://#{gem_repo2}" }
        expect(installer.install(["re-plugin"], opts)).
          to include("re-plugin" => plugin_gems("re-plugin-1.0").to_s)
      end

      it "accepts multiple plugins" do
        opts = { :source => "file://#{gem_repo2}" }

        expect(installer.install(["re-plugin", "ma-plugin"], opts)).
          to include("re-plugin" => plugin_gems("re-plugin-1.0").to_s,
                     "ma-plugin" => plugin_gems("ma-plugin-1.0").to_s)
      end
    end
  end
end
