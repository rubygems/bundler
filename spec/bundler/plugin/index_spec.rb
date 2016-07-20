# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::Index do
  Index = Bundler::Plugin::Index

  subject(:index) { Index.new }

  before do
    gemfile ""
  end

  describe "#register plugin" do
    before do
      path = lib_path("new-plugin")
      index.register_plugin("new-plugin", path.to_s, [path.join("lib").to_s], [], [])
    end

    it "is available for retrieval" do
      expect(index.plugin_path("new-plugin")).to eq(lib_path("new-plugin"))
    end

    it "load_paths is available for retrival" do
      expect(index.load_paths("new-plugin")).to eq([lib_path("new-plugin").join("lib").to_s])
    end

    it "is persistent" do
      new_index = Index.new
      expect(new_index.plugin_path("new-plugin")).to eq(lib_path("new-plugin"))
    end

    it "load_paths are persistant" do
      new_index = Index.new
      expect(new_index.load_paths("new-plugin")).to eq([lib_path("new-plugin").join("lib").to_s])
    end
  end

  describe "commands" do
    before do
      path = lib_path("cplugin")
      index.register_plugin("cplugin", path.to_s, [path.join("lib").to_s], ["newco"], [])
    end

    it "returns the plugins name on query" do
      expect(index.command_plugin("newco")).to eq("cplugin")
    end

    it "raises error on conflict" do
      expect do
        index.register_plugin("aplugin", lib_path("aplugin").to_s, lib_path("aplugin").join("lib").to_s, ["newco"], [])
      end.to raise_error(Index::CommandConflict)
    end

    it "is persistent" do
      new_index = Index.new
      expect(new_index.command_plugin("newco")).to eq("cplugin")
    end
  end

  describe "source" do
    before do
      path = lib_path("splugin")
      index.register_plugin("splugin", path.to_s, [path.join("lib").to_s], [], ["new_source"])
    end

    it "returns the plugins name on query" do
      expect(index.source_plugin("new_source")).to eq("splugin")
    end

    it "raises error on conflict" do
      expect do
        index.register_plugin("aplugin", lib_path("aplugin").to_s, lib_path("aplugin").join("lib").to_s, [], ["new_source"])
      end.to raise_error(Index::SourceConflict)
    end

    it "is persistent" do
      new_index = Index.new
      expect(new_index.source_plugin("new_source")).to eq("splugin")
    end
  end

  describe "global index" do
    before do
      Dir.chdir tmp
      path = lib_path("gplugin")
      index.register_plugin("gplugin", path.to_s, [path.join("lib").to_s], [], ["glb_source"])
      Dir.chdir bundled_app
    end

    it "skips sources" do
      new_index = Index.new
      expect(new_index.source_plugin("glb_source")).to be_falsy
    end
  end

  describe "after conflict" do
    before do
      path = lib_path("aplugin")
      index.register_plugin("aplugin", path.to_s, [path.join("lib").to_s], ["foo"], ["bar"])
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
          path = lib_path("cplugin")
          index.register_plugin("cplugin", path.to_s, [path.join("lib").to_s], ["foo"], ["xbar"])
        end.to raise_error(Index::CommandConflict)
      end

      include_examples "it cleans up"
    end

    context "on source conflict it cleans up" do
      before do
        expect do
          path = lib_path("cplugin")
          index.register_plugin("cplugin", path.to_s, [path.join("lib").to_s], ["xfoo"], ["bar"])
        end.to raise_error(Index::SourceConflict)
      end

      include_examples "it cleans up"
    end

    context "on command and source conflict it cleans up" do
      before do
        expect do
          path = lib_path("cplugin")
          index.register_plugin("cplugin", path.to_s, [path.join("lib").to_s], ["foo"], ["bar"])
        end.to raise_error(Index::CommandConflict)
      end

      include_examples "it cleans up"
    end
  end
end
