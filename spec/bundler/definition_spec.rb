require 'spec_helper'
require 'bundler/definition'

describe Bundler::Definition do
  before do
    allow(Bundler).to receive(:settings){ Bundler::Settings.new(".") }
    allow(Bundler).to receive(:default_gemfile){ Pathname.new("Gemfile") }
  end

  describe "#lock" do
    context "when it's not possible to write to the file" do
      subject{ Bundler::Definition.new(nil, [], Bundler::SourceList.new, []) }

      it "raises an InstallError with explanation" do
        expect(File).to receive(:open).with("Gemfile.lock", "wb").
          and_raise(Errno::EACCES)
        expect{ subject.lock("Gemfile.lock") }.
          to raise_error(Bundler::InstallError)
      end
    end
  end
end
