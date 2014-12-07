require 'spec_helper'

describe Bundler::Fetcher do
  before do
    allow(Bundler).to receive(:root){ Pathname.new("root") }
  end

  describe "#user_agent" do
    it "builds user_agent with current ruby version and Bundler settings" do
      allow(Bundler.settings).to receive(:all).and_return(["foo", "bar"])
      expect(described_class.user_agent).to match(/bundler\/(\d.)/)
      expect(described_class.user_agent).to match(/rubygems\/(\d.)/)
      expect(described_class.user_agent).to match(/ruby\/(\d.)/)
      expect(described_class.user_agent).to match(/options\/foo,bar/)
    end
  end
end
