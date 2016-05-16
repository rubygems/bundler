# frozen_string_literal: true
require "spec_helper"

describe Bundler::Index do
  let(:specs) { [] }
  subject { described_class.build {|i| i.use(specs) } }

  context "specs with a nil platform" do
    let(:spec) do
      Gem::Specification.new do |s|
        s.name = "json"
        s.version = "1.8.3"
        allow(s).to receive(:platform).and_return(nil)
      end
    end
    let(:specs) { [spec] }

    describe "#search_by_spec" do
      it "finds the spec when a nil platform is specified" do
        expect(subject.search(spec)).to eq([spec])
      end

      it "finds the spec when a ruby platform is specified" do
        query = spec.dup.tap {|s| s.platform = "ruby" }
        expect(subject.search(query)).to eq([spec])
      end
    end
  end
end
