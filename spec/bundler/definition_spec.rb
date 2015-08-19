require "spec_helper"
require "bundler/definition"

describe Bundler::Definition do
  before do
    allow(Bundler).to receive(:settings) { Bundler::Settings.new(".") }
    allow(Bundler).to receive(:default_gemfile) { Pathname.new("gems.rb") }
    allow(Bundler).to receive(:ui) { double("UI", :info => "") }
  end

  describe "#lock" do
    context "when it's not possible to write to the file" do
      subject { Bundler::Definition.new(nil, [], Bundler::SourceList.new, []) }

      it "raises an InstallError with explanation" do
        expect(File).to receive(:open).with("gems.locked", "wb").
          and_raise(Errno::EACCES)
        expect { subject.lock("gems.locked") }.
          to raise_error(Bundler::PermissionError, /gems\.locked/)
      end
    end
  end
end
