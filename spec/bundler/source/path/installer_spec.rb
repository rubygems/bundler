require 'spec_helper'

describe Bundler::Source::Path::Installer do
  let(:gemspec) { Gem::Specification.new("fakegem", "1.0") }

  before do
    Bundler.stub(:requires_sudo?){ false }
  end

  describe "#initialize" do
    it "makes an options hash available" do
      described_class.new(gemspec).options.should be_a(Hash)
      described_class.new(gemspec, {}).options.should be_a(Hash)
    end

    it "initializes some default options" do
      inst = described_class.new(gemspec)
      inst.options.should be_a(Hash)
      inst.options.should_not be_empty
    end

    it 'preserves passed-in options' do
      opts = described_class.new(gemspec, wrappers: !described_class::DEFAULT_OPTIONS[:wrappers]).options
      opts[:wrappers].should eql(!described_class::DEFAULT_OPTIONS[:wrappers])
    end
  end
end
