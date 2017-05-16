# frozen_string_literal: true
require "spec_helper"

RSpec.describe Bundler::UI::Shell do
  subject { described_class.new }

  before { subject.level = "debug" }

  describe "#info" do
    it "prints to stdout" do
      expect { subject.info("info") }.to output("info\n").to_stdout
    end
  end

  describe "#confirm" do
    it "prints to stdout" do
      expect { subject.confirm("confirm") }.to output("confirm\n").to_stdout
    end
  end

  describe "#warn" do
    it "prints to stdout" do
      expect { subject.warn("warning") }.to output("warning\n").to_stdout
    end
  end

  describe "#debug" do
    it "prints to stdout" do
      expect { subject.debug("debug") }.to output("debug\n").to_stdout
    end
  end

  describe "#error" do
    it "prints to stdout" do
      expect { subject.error("error!!!") }.to output("error!!!\n").to_stdout
    end

    context "when stderr flag is enabled" do
      before { bundle "config stderr true" }
      it "prints to stderr" do
        expect { subject.error("error!!!") }.to output("\e[31merror!!!\e[0m").to_stderr
      end
    end
  end
end
