require "spec_helper"

describe Bundler::RemoteSpecification do
  it "is Comparable" do
    expect(described_class.ancestors).to include(Comparable)
  end

  describe "#<=>" do
    let(:name) { "foo" }
    let(:version) { Gem::Version.new("1.0.0") }
    let(:newer_version) { Gem::Version.new("1.1.0") }
    let(:older_version) { Gem::Version.new("0.9.0") }
    let(:platform) { Gem::Platform::RUBY }

    subject do
      Bundler::RemoteSpecification.new(name, version, platform, nil)
    end

    context "given a Gem::Specification" do
      let(:same_gem) do
        Gem::Specification.new(name, version)
      end

      let(:different_name) do
        Gem::Specification.new("bar", version)
      end

      let(:newer_gem) do
        Gem::Specification.new(name, newer_version)
      end

      let(:older_gem) do
        Gem::Specification.new(name, older_version)
      end

      let(:different_platform) do
        s = Gem::Specification.new(name, version)
        s.platform = Gem::Platform.new "x86-mswin32"
        s
      end

      it "compares based on name" do
        expect(subject <=> different_name).not_to eq(0)
      end

      it "compares based on version" do
        expect(subject <=> same_gem).to eq(0)
        expect(subject).to be < newer_gem
        expect(subject).to be > older_gem
      end

      it "compares based on platform" do
        expect(subject <=> different_platform).not_to eq(0)
      end
    end
  end
end
