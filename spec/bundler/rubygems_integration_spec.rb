require 'spec_helper'

describe Bundler::RubygemsIntegration do
  it "uses the same chdir lock as rubygems", :rubygems => "2.1" do
    expect(Bundler.rubygems.ext_lock).to eq(Gem::Ext::Builder::CHDIR_MONITOR)
  end

  context "#validate" do
    let(:spec) { double("spec", :summary => "") }

    it "validates without arguments", :rubygems => "< 1.7" do
      expect(spec).to receive(:validate).with(no_args)
      Bundler.rubygems.validate(spec)
    end

    it "validates with packaging mode disabled", :rubygems => "1.7" do
      expect(spec).to receive(:validate).with(false)
      Bundler.rubygems.validate(spec)
    end
  end
end
