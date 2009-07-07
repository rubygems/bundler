require "rubygems/remote_fetcher"

module Bundler
  class Fetcher
    def self.fetch(source)
      deflated = Gem::RemoteFetcher.fetcher.fetch_path("#{source}/Marshal.4.8.Z")
      inflated = Gem.inflate deflated
      index    = Marshal.load(inflated)
      FasterSourceIndex.new(index)
    rescue Gem::RemoteFetcher::FetchError => e
      raise ArgumentError, "#{source} is not a valid source: #{e.message}"
    end
  end
end