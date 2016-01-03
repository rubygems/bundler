require "spec_helper"
require "bundler/shared_helpers"

module TargetNamespace
  VALID_CONSTANT = 1
end

describe Bundler::SharedHelpers do
  describe "#const_get_safely" do
    context "when the namespace does have the requested constant" do
      subject { Bundler::SharedHelpers.const_get_safely(:VALID_CONSTANT, TargetNamespace) }
      it "returns the value of the requested constant" do
        expect(subject).to eq(1)
      end
    end
    context "when the requested constant is passed as a string" do
      subject { Bundler::SharedHelpers.const_get_safely("VALID_CONSTANT", TargetNamespace) }
      it "returns the value of the requested constant" do
        expect(subject).to eq(1)
      end
    end
    context "when the namespace does not have the requested constant" do
      subject { Bundler::SharedHelpers.const_get_safely("INVALID_CONSTANT", TargetNamespace) }
      it "returns nil" do
        expect(subject).to eq(nil)
      end
    end
  end
end
