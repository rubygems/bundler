require File.join(File.dirname(__FILE__), "spec_helper")

describe "Fetcher" do
  it "gets the remote index and returns a source index" do
    index = Bundler::Fetcher.fetch("file://#{File.expand_path(File.dirname(__FILE__))}/fixtures")
    index.should be_kind_of(FasterSourceIndex)
  end

  it "raises if the source is invalid" do
    lambda { Bundler::Fetcher.fetch("file://not/a/gem/source") }.should raise_error(ArgumentError)
    lambda { Bundler::Fetcher.fetch("http://localhost") }.should raise_error(ArgumentError)
    lambda { Bundler::Fetcher.fetch("http://google.com/not/a/gem/location") }.should raise_error(ArgumentError)
  end
end