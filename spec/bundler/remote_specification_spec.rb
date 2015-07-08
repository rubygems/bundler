require "spec_helper"

describe Bundler::RemoteSpecification do
  it "is Comparable" do
    expect(described_class.ancestors).to include(Comparable)
  end

  describe "#<=>" do
    let(:name) { "foo" }
    let(:version) { Gem::Version.new("1.0.0") }
    let(:platform) { Gem::Platform::RUBY }

    let(:other_name) { name }
    let(:other_version) { version }
    let(:other_platform) { platform }

    subject do
      Bundler::RemoteSpecification.new(name, version, platform, nil)
    end

    shared_examples_for "a comparison" do
      context "which exactly matches" do
        it "returns 0" do
          expect(subject <=> other).to eq(0)
        end
      end

      context "which is different by name" do
        let(:other_name) { "a" }
        it "doesn't return 0" do
          expect(subject <=> other).not_to eq(0)
        end
      end

      context "which has a lower version" do
        let(:other_version) { Gem::Version.new("0.9.0") }
        it "returns 1" do
          expect(subject <=> other).to eq(1)
        end
      end

      context "which has a higher version" do
        let(:other_version) { Gem::Version.new("1.1.0") }
        it "returns -1" do
          expect(subject <=> other).to eq(-1)
        end
      end

      context "which has a different platform" do
        let(:other_platform) { Gem::Platform.new("x86-mswin32") }
        it "doesn't return 0" do
          expect(subject <=> other).not_to eq(0)
        end
      end
    end

    context "comparing another Bundler::RemoteSpecification" do
      let(:other) do
        Bundler::RemoteSpecification.new(other_name, other_version,
                                         other_platform, nil)
      end

      it_should_behave_like "a comparison"
    end

    context "comparing a Gem::Specification" do
      let(:other) do
        Gem::Specification.new(other_name, other_version).tap do |s|
          s.platform = other_platform
        end
      end

      it_should_behave_like "a comparison"
    end
  end
end
