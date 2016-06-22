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
    let(:opts) { { "version" => "~> 1.0", "source" => "foo" } }

    before do
      allow(installer).to receive(:install).with(["new-plugin"], opts) do
        { "new-plugin" => lib_path("new-plugin") }
      end
    end

    it "passes the name and options to installer" do
      allow(installer).to receive(:install).with(["new-plugin"], opts) do
        { "new-plugin" => lib_path("new-plugin").to_s }
      end.once

      subject.install ["new-plugin"], opts
    end

    it "validates the installed plugin" do
      allow(subject).
        to receive(:validate_plugin!).with(lib_path("new-plugin")).once

      subject.install ["new-plugin"], opts
    end

    it "registers the plugin with index" do
      allow(index).to receive(:register_plugin).
        with("new-plugin", lib_path("new-plugin").to_s, []).once
      subject.install ["new-plugin"], opts
    end

    context "multiple plugins" do
      it do
        allow(installer).to receive(:install).
          with(["new-plugin", "another-plugin"], opts) do
          {
            "new-plugin" => lib_path("new-plugin"),
            "another-plugin" => lib_path("another-plugin"),
          }
        end.once

        allow(subject).to receive(:validate_plugin!).twice
        allow(index).to receive(:register_plugin).twice
        subject.install ["new-plugin", "another-plugin"], opts
      end
    end
  end

  describe "evaluate gemfile for plugins" do
    let(:definition) { double("definition") }
    let(:builder) { double("builder") }
    let(:gemfile) { bundled_app("Gemfile") }

    before do
      allow(Plugin::DSL).to receive(:new) { builder }
      allow(builder).to receive(:eval_gemfile).with(gemfile)
      allow(builder).to receive(:to_definition) { definition }
      allow(builder).to receive(:inferred_plugins) { [] }
    end

    it "doesn't calls installer without any plugins" do
      allow(definition).to receive(:dependencies) { [] }
      allow(installer).to receive(:install_definition).never

      subject.gemfile_install(gemfile)
    end

    context "with dependencies" do
      let(:plugin_paths) do
        {
          "new-plugin" => lib_path("new-plugin"),
          "another-plugin" => lib_path("another-plugin"),
        }
      end

      before do
        allow(definition).to receive(:dependencies) { [Bundler::Dependency.new("new-plugin", ">=0"), Bundler::Dependency.new("another-plugin", ">=0")] }
        allow(installer).to receive(:install_definition) { plugin_paths }
      end

      it "should validate and register the plugins" do
        expect(subject).to receive(:validate_plugin!).twice
        expect(subject).to receive(:register_plugin).twice

        subject.gemfile_install(gemfile)
      end

      it "should pass the optional plugins to #register_plugin" do
        allow(builder).to receive(:inferred_plugins) { ["another-plugin"] }

        expect(subject).to receive(:register_plugin).
          with("new-plugin", plugin_paths["new-plugin"], false).once

        expect(subject).to receive(:register_plugin).
          with("another-plugin", plugin_paths["another-plugin"], true).once

        subject.gemfile_install(gemfile)
      end
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

  describe "#source?" do
    it "returns true value for sources in index" do
      allow(index).
        to receive(:command_plugin).with("foo-source") { "my-plugin" }
      result = subject.command? "foo-source"
      expect(result).to be_truthy
    end

    it "returns false value for source not in index" do
      allow(index).to receive(:command_plugin).with("foo-source") { nil }
      result = subject.command? "foo-source"
      expect(result).to be_falsy
    end
  end

  describe "#source" do
    it "raises UnknownSourceError when source is not found" do
      allow(index).to receive(:source_plugin).with("bar") { nil }
      expect { subject.source("bar") }.
        to raise_error(Plugin::UnknownSourceError)
    end

    it "loads the plugin, if not loaded" do
      allow(index).to receive(:source_plugin).with("foo-bar") { "plugin_name" }

      expect(subject).to receive(:load_plugin).with("plugin_name")
      subject.source("foo-bar")
    end

    it "returns the class registered with #add_source" do
      allow(index).to receive(:source_plugin).with("foo") { "plugin_name" }
      stub_const "NewClass", Class.new

      subject.add_source("foo", NewClass)
      expect(subject.source("foo")).to be(NewClass)
    end
  end

  describe "#source_from_lock" do
    it "returns instance of registered class initialized with locked opts" do
      opts = { "type" => "l_source", "remote" => "xyz", "other" => "random" }
      allow(index).to receive(:source_plugin).with("l_source") { "plugin_name" }

      stub_const "SClass", Class.new
      s_instance = double(:s_instance)
      subject.add_source("l_source", SClass)

      expect(SClass).to receive(:new).with(hash_including(
                                             "type" => "l_source", "uri" => "xyz", "other" => "random")) { s_instance }
      expect(subject.source_from_lock(opts)).to be(s_instance)
    end
  end
end
