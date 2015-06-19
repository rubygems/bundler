require "spec_helper"

describe Bundler::RemoteSpecification do
  subject(:spec) { Bundler::RemoteSpecification.new("foo", "1.2", "ruby", fetcher) }
  let(:fetcher) { double("SpecFetcher", :fetch_spec => rubygems_spec)}
  let(:rubygems_spec) { Gem::Specification.new("foo", "1.2") }

  describe "<=>" do
    let(:other_spec) { Gem::Specification.new("bar", "1.0") }
    it "sorts with Gem::Specification" do
      expect(spec <=> other_spec).to eq(1)
    end
  end
end