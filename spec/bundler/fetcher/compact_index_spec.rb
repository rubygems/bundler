# frozen_string_literal: true
require "spec_helper"

describe Bundler::Fetcher::CompactIndex do
  let(:downloader)  { double(:downloader) }
  let(:remote)      { double(:remote, :cache_slug => "lsjdf") }
  let(:display_uri) { URI("http://sample_uri.com") }
  let(:compact_index) { described_class.new(downloader, remote, display_uri) }

  # Testing private method. Do not commit.
  describe '#specs_for_names' do
    it "has only one thread open at the end of the run" do
      compact_index.specs_for_names(['lskdjf'])

      thread_count = Thread.list.select {|thread| thread.status == "run" }.count
      expect(thread_count).to eq 1
    end

    it "calls worker#stop during the run" do
      expect_any_instance_of(Bundler::Worker).to receive(:stop).at_least(:once)

      compact_index.specs_for_names(['lskdjf'])
    end
  end
end
