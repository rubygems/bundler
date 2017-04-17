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

    describe "#to_spec" do
      it "returns a Gem::Specification" do
        expect(with_gem_stub_spec.to_spec).to be_a(Gem::Specification)
        expect(with_bundler_stub_spec.to_spec).to be_a(Gem::Specification)
      end
    end
  end
end
