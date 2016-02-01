# frozen_string_literal: true
require "spec_helper"

describe Bundler::PathPreserver do
  describe "#preserve_path_in_environment" do
    subject { described_class.preserve_path_in_environment(env_var, env) }

    context "env_var is PATH" do
      let(:env_var)       { "PATH" }
      let(:path)          { "/path/here" }
      let(:original_path) { "/original/path/here" }

      context "when _ORIGINAL_PATH in env is nil" do
        let(:env)  { { "ORIGINAL_PATH" => nil, "PATH" => path } }

        it "should set _ORIGINAL_PATH of env to value of PATH from env" do
          expect(env["_ORIGINAL_PATH"]).to be_nil
          subject
          expect(env["_ORIGINAL_PATH"]).to eq("/path/here")
        end
      end

      context "when original_path in env is empty" do
        let(:env)  { { "_ORIGINAL_PATH" => "", "PATH" => path } }

        it "should set _ORIGINAL_PATH of env to value of PATH from env" do
          expect(env["_ORIGINAL_PATH"]).to be_empty
          subject
          expect(env["_ORIGINAL_PATH"]).to eq("/path/here")
        end
      end

      context "when path in env is nil" do
        let(:env)  { { "_ORIGINAL_PATH" => original_path, "PATH" => nil } }

        it "should set PATH of env to value of _ORIGINAL_PATH from env" do
          expect(env["PATH"]).to be_nil
          subject
          expect(env["PATH"]).to eq("/original/path/here")
        end
      end

      context "when path in env is empty" do
        let(:env)  { { "_ORIGINAL_PATH" => original_path, "PATH" => "" } }

        it "should set PATH of env to value of _ORIGINAL_PATH from env" do
          expect(env["PATH"]).to be_empty
          subject
          expect(env["PATH"]).to eq("/original/path/here")
        end
      end
    end
  end
end
