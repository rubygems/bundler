require "spec_helper"

require "bundler/shared_helpers"

RSpec.describe Bundler::SharedHelpers do
  describe "#set_bundle_environment" do
    it "does not raise an exception when the filesystem prsents utf-8 paths and env is windows-1251 encoded" do
      # cyrillic c encoded with windows-1251
      allow(ENV).to receive(:[]).and_return([209].pack("c*").force_encoding("windows-1251"))

      # unicode heart emoji
      allow(Bundler).to receive(:bundle_path).and_return([240, 159, 146, 149].pack("c*").force_encoding("utf-8"))

      foo = Class.new do
        include Bundler::SharedHelpers
      end

      expect {
        foo.new.set_bundle_environment
      }.to_not raise_error
    end
  end
end
