# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::Index do
  Index = Bundler::Plugin::Index

  subject(:index) { Index.new }

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

    it "is persistent" do
      new_index = Index.new
      expect(new_index.command_plugin("newco")).to eq("cplugin")
    end
  end

  describe "source" do
    before do
      index.register_plugin("splugin", lib_path("splugin").to_s, [], ["new_source"])
    end

    it "returns the plugins name on query" do
      expect(index.source_plugin("new_source")).to eq("splugin")
    end

    it "raises error on conflict" do
      expect do
        index.register_plugin("aplugin", lib_path("aplugin").to_s, [], ["new_source"])
      end.to raise_error(Index::SourceConflict)
    end

    it "is persistent" do
      new_index = Index.new
      expect(new_index.source_plugin("new_source")).to eq("splugin")
    end
  end

  describe "after conflict" do
    before do
      index.register_plugin("aplugin", lib_path("aplugin").to_s, ["foo"], ["bar"])
    end

    shared_examples "it cleans up" do
      it "the path" do
        expect(index.installed?("cplugin")).to be_falsy
      end

      it "the command" do
        expect(index.command_plugin("xfoo")).to be_falsy
      end

      it "the source" do
        expect(index.source_plugin("xbar")).to be_falsy
      end
    end

    context "on command conflict it cleans up" do
      before do
        expect do
          index.register_plugin("cplugin", lib_path("cplugin").to_s, ["foo"], ["xbar"])
        end.to raise_error(Index::CommandConflict)
      end

      include_examples "it cleans up"
    end

    context "on source conflict it cleans up" do
      before do
        expect do
          index.register_plugin("cplugin", lib_path("cplugin").to_s, ["xfoo"], ["bar"])
        end.to raise_error(Index::SourceConflict)
      end

      include_examples "it cleans up"
    end

    context "on command and source conflict it cleans up" do
      before do
        expect do
          index.register_plugin("cplugin", lib_path("cplugin").to_s, ["foo"], ["bar"])
        end.to raise_error(Index::CommandConflict)
      end

      include_examples "it cleans up"
    end
  end
end
