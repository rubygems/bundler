require "spec_helper"

describe Bundler::Source::Git do
  describe "#to_lock" do
    let(:git_proxy) { double(:git_proxy, "revision" => "ABC123") }

    it "removes credentials from uri" do
      expect(Bundler::Source::Git::GitProxy).to receive(:new).exactly(2).times.and_return(git_proxy)
      expect(Bundler).to receive(:requires_sudo?).exactly(2).times.and_return(false)
      expect(Bundler).to receive(:cache).exactly(2).times.and_return(Pathname.new("Idontcare"))
      {
        "https://u:p@github.com/foo/foo.git" => "https://github.com/foo/foo.git",
        "http://u:p@github.com/foo/foo.git" => "http://github.com/foo/foo.git"
      }.each do |uri_in, uri_out|
        g = described_class.new("revision" => "ABC123", "uri" => uri_in)
        expect(g.to_lock).to eq(<<-STR)
GIT
  remote: #{uri_out}
  revision: ABC123
  specs:
STR
      end
    end
  end
end
