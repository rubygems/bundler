# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::Index do
  Index = Bundler::Plugin::Index

  subject(:index) { Index.new }

  before do
    build_lib "new-plugin", :path => lib_path("new-plugin") do |s|
      s.write "plugins.rb"
    end
  end

  describe "#register plugin" do
    before do
      index.register_plugin("new-plugin", lib_path("new-plugin").to_s, [], [])
    end

    it "is available for retrieval" do
      expect(index.plugin_path("new-plugin")).to eq(lib_path("new-plugin"))
    end

    it "is persistent" do
      new_index = Index.new
      expect(new_index.plugin_path("new-plugin")).to eq(lib_path("new-plugin"))
    end
  end

  describe "commands" do
    before do
      index.register_plugin("cplugin", lib_path("cplugin").to_s, ["newco"], [])
    end

    it "returns the plugins name on query" do
      expect(index.command_plugin("newco")).to eq("cplugin")
    end

    it "raises error on conflict" do
      expect do
        index.register_plugin("aplugin", lib_path("aplugin").to_s, ["newco"], [])
      end.to raise_error(Index::CommandConflict)
    end
  end
end
