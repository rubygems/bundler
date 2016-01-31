# frozen_string_literal: true
require "spec_helper"

describe Bundler::Source::Git::GitProxy do
  let(:uri) { "https://github.com/bundler/bundler.git" }
  subject { described_class.new(Pathname("path"), uri, "HEAD") }

  context "with configured credentials" do
    it "adds username and password to URI" do
      Bundler.settings[uri] = "u:p"
      expect(subject).to receive(:git_retry).with(match("https://u:p@github.com/bundler/bundler.git"))
      subject.checkout
    end

    it "adds username and password to URI for host" do
      Bundler.settings["github.com"] = "u:p"
      expect(subject).to receive(:git_retry).with(match("https://u:p@github.com/bundler/bundler.git"))
      subject.checkout
    end

    it "does not add username and password to mismatched URI" do
      Bundler.settings["https://u:p@github.com/bundler/bundler-mismatch.git"] = "u:p"
      expect(subject).to receive(:git_retry).with(match(uri))
      subject.checkout
    end

    it "keeps original userinfo" do
      Bundler.settings["github.com"] = "u:p"
      original = "https://orig:info@github.com/bundler/bundler.git"
      subject = described_class.new(Pathname("path"), original, "HEAD")
      expect(subject).to receive(:git_retry).with(match(original))
      subject.checkout
    end
  end
end
