# frozen_string_literal: true
require "spec_helper"

require "bundler/plugin"

describe Bundler::Plugin::API do
  context "plugin declarations" do
    before do
      stub_const "UserPluginClass", Class.new(Bundler::Plugin::API)
    end

    it "declares a command plugin with same class as handler" do
      success = false
      allow(Bundler::Plugin).to receive(:add_command).with("meh", UserPluginClass) { success = true }

      UserPluginClass.command "meh"

      expect(success).to be true
    end

    it "accepts another class as argument that handles the command" do
      success = false
      stub_const "NewClass", Class.new
      allow(Bundler::Plugin).to receive(:add_command).with("meh", NewClass) { success = true }

      UserPluginClass.command "meh", NewClass
      expect(success).to be true
    end
  end

  context "bundler interfaces provided" do
    before do
      stub_const "UserPluginClass", Class.new(Bundler::Plugin::API)
    end

    subject(:api) { UserPluginClass.new }

    # A test of delegation
    it "provides the bundler settings" do
      expect(api.settings).to eq(Bundler.settings)
    end
  end
end
