require "spec_helper"

describe Bundler::Source::Git do
  describe "#to_lock" do
    let(:git_proxy) { double(:git_proxy, "revision" => "ABC123") }

    shared_examples_for "GitHub URIs" do |uri_in, uri_out|
      it "removes the credentials" do
        expect(Bundler::Source::Git::GitProxy).to receive(:new).and_return(git_proxy)
        expect(Bundler).to receive(:requires_sudo?).and_return(false)
        expect(Bundler).to receive(:cache).and_return(Pathname.new("Idontcare"))
        g = described_class.new("revision" => "ABC123", "uri" => uri_in)
        expect(g.to_lock).to eq(<<-STR)
GIT
  remote: #{uri_out}
  revision: ABC123
  specs:
STR
      end
    end

    context "with https" do
      it_behaves_like "GitHub URIs", "https://u:p@github.com/foo/foo.git", "https://github.com/foo/foo.git"
    end

    context "with http" do
      it_behaves_like "GitHub URIs", "http://u:p@github.com/foo/foo.git", "http://github.com/foo/foo.git"
    end
  end
end
