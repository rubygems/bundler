# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin do
  Plugin = Bundler::Plugin

  let(:installer) { double(:installer) }
  let(:index) { double(:index) }

  before do
    build_lib "new-plugin", :path => lib_path("new-plugin") do |s|
      s.write "plugins.rb"
    end

    build_lib "another-plugin", :path => lib_path("another-plugin") do |s|
      s.write "plugins.rb"
    end

    allow(Plugin::Installer).to receive(:new) { installer }
    allow(Plugin).to receive(:index) { index }
    allow(index).to receive(:register_plugin)
  end

  describe "install command" do
    let(:opts) {{"version" => "~> 1.0", "source" => "foo"}}

    before do
      allow(installer).
        to receive(:install).with("new-plugin", opts) {lib_path("new-plugin")}
    end

    it "passes the name and options to installer" do
      allow(installer).to receive(:install).with("new-plugin", opts) do
        lib_path("new-plugin")
      end.once

      subject.install "new-plugin", opts
    end

    it "validates the installed plugin" do
      allow(subject).
        to receive(:validate_plugin!).with(lib_path("new-plugin")).once

      subject.install "new-plugin", opts
    end

    it "registers the plugin with index" do
      allow(index).to receive(:register_plugin).
        with("new-plugin", lib_path("new-plugin").to_s, []).once
      subject.install "new-plugin", opts
    end
  end

  describe "evaluate gemfile for plugins" do
    let(:definition) { double("definition") }
    let(:gemfile) { bundled_app("Gemfile") }

    before do
      allow(Plugin::DSL).to receive(:evaluate) { definition }
    end

    it "doesn't calls installer without any plugins" do
      allow(definition).to receive(:dependencies) { [] }
      allow(installer).to receive(:install_definition).never

      subject.eval_gemfile(gemfile)
    end

    it "should validate and register the plugins" do
      allow(definition).to receive(:dependencies) { [1, 2] }
      plugin_paths = {
        "new-plugin" => lib_path("new-plugin"),
        "another-plugin" => lib_path("another-plugin"),
      }
      allow(installer).to receive(:install_definition) {plugin_paths}

      expect(subject).to receive(:validate_plugin!).twice
      expect(subject).to receive(:register_plugin).twice

      subject.eval_gemfile(gemfile)
    end
  end

  describe "#command?" do
    it "returns true value for commands in index" do
      allow(index).
        to receive(:command_plugin).with("newcommand") { "my-plugin" }
      result = subject.command? "newcommand"
      expect(result).to be_truthy
    end

    it "returns false value for commands not in index" do
      allow(index).to receive(:command_plugin).with("newcommand") { nil }
      result = subject.command? "newcommand"
      expect(result).to be_falsy
    end
  end

  describe "#exec_command" do
    it "raises UndefinedCommandError when command is not found" do
      allow(index).to receive(:command_plugin).with("newcommand") { nil }
      expect { subject.exec_command("newcommand", []) }.
        to raise_error(Plugin::UndefinedCommandError)
    end
  end
end
