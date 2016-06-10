# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::DSL do
  DSL = Bundler::Plugin::DSL

  subject(:dsl) { Bundler::Plugin::DSL.new }

  before do
    allow(Bundler).to receive(:root) { Pathname.new "/" }
  end

  describe "it ignores only the methods defined in Bundler::Dsl" do
    it "doesn't raises error for Dsl methods" do
      expect { dsl.install_if }.not_to raise_error
    end

    it "raises error for other methods" do
      expect { dsl.no_method }.to raise_error(DSL::PluginGemfileError)
    end
  end
end
