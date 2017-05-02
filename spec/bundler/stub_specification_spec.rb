# frozen_string_literal: true
require "spec_helper"

if Bundler.rubygems.provides?(">= 2.1")
  RSpec.describe Bundler::StubSpecification do
    let(:with_gem_stub_spec) do
      stub = Gem::Specification.stubs.first
      described_class.from_stub(stub)
    end

    let(:with_bundler_stub_spec) do
      described_class.from_stub(with_gem_stub_spec)
    end

    describe "#from_stub" do
      it "returns the same stub if already a Bundler::StubSpecification" do
        stub = described_class.from_stub(with_bundler_stub_spec)
        expect(stub).to be(with_bundler_stub_spec)
      end
    end
  end
end
