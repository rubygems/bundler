# frozen_string_literal: true
require "spec_helper"

describe Bundler::Plugin::DSL do
  subject(:dsl) { Bundler::Plugin::DSL.new }

  before do
    allow(Bundler).to receive(:root) { Pathname.new "/" }
  end

  describe "it ignores only the methods defined in Bundler::Dsl" do
    it "doesn't raises error for Dsl methods" do
      expect { dsl.install_if }.not_to raise_error
    end

    it "raises error for other methods" do
      expect { dsl.no_method }.to raise_error(Bundler::GemfileError)
    end
  end
end
