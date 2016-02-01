# frozen_string_literal: true
require "spec_helper"
require "bundler/definition"

describe Bundler::Definition do
  before do
    allow(Bundler).to receive(:settings) { Bundler::Settings.new(".") }
    allow(Bundler).to receive(:default_gemfile) { Pathname.new("Gemfile") }
    allow(Bundler).to receive(:ui) { double("UI", :info => "") }
  end

  describe "#lock" do
    context "when it's not possible to write to the file" do
      subject { Bundler::Definition.new(nil, [], Bundler::SourceList.new, []) }

      it "raises an PermissionError with explanation" do
        expect(File).to receive(:open).with("Gemfile.lock", "wb").
          and_raise(Errno::EACCES)
        expect { subject.lock("Gemfile.lock") }.
          to raise_error(Bundler::PermissionError, /Gemfile\.lock/)
      end
    end
    context "when a temporary resource access issue occurs" do
      subject { Bundler::Definition.new(nil, [], Bundler::SourceList.new, []) }

      it "raises a TemporaryResourceError with explanation" do
        expect(File).to receive(:open).with("Gemfile.lock", "wb").
          and_raise(Errno::EAGAIN)
        expect { subject.lock("Gemfile.lock") }.
          to raise_error(Bundler::TemporaryResourceError, /temporarily unavailable/)
      end
    end
  end
end
