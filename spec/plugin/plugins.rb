# frozen_string_literal: true
require "spec_helper"

describe "bundle plugin" do
  describe "install a plugin" do
    it "downloads the plugin to user bundler dir" do
      build_git "foo" do |s|
        s.write "plugin.rb", ""
      end

      bundle "plugin foo --install --git file://#{lib_path("foo-1.0")}"
      expect(out).to include("Installed plugin foo")

      expect(Bundler::Plugin.plugin_root.join("foo")).to be_directory
    end
  end

  describe "command line plugin" do
    it "executes" do
      build_git "foo" do |s|
        s.write "plugin.rb", <<-P
          class DemoPlugin < Bundler::Plugin::Base
            command "demop"

            def execute(args)
              puts "hello world"
            end
          end
        P
      end

      bundle "plugin foo --install --git file://#{lib_path("foo-1.0")}"

      bundle "demop"

      expect(out).to include("hello world")
    end
  end
end
