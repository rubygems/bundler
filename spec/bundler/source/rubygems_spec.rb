require 'spec_helper'

describe Bundler::Source::Rubygems do
  before do
    allow(Bundler).to receive(:root){ Pathname.new("root") }
  end

  describe "caches" do
    it "includes Bundler.app_cache" do
      expect(subject.caches).to include(Bundler.app_cache)
    end

    it "includes GEM_PATH entries" do
      Gem.path.each do |path|
        expect(subject.caches).to include(File.expand_path("#{path}/cache"))
      end
    end

    it "is an array of strings or pathnames" do
      subject.caches.each do |cache|
        expect([String, Pathname]).to include(cache.class)
      end
    end
  end

  describe "#fetchers" do
    let(:remotes) { [URI("s3://foo"), URI("http://foo")] }
    subject(:source) { Bundler::Source::Rubygems.new("remotes" => remotes) }

    it "turns s3 paths into S3Fetcher objects and other paths into Fetcher objects" do
      result = source.fetchers
      expect(result.first).to be_an_instance_of Bundler::S3Fetcher
      expect(result.last).to be_an_instance_of Bundler::Fetcher
    end
  end
end
