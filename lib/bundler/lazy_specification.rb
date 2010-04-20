require "uri"
require "rubygems/spec_fetcher"

module Bundler
  # Represents a lazily loaded gem specification, where the full specification
  # is on the source server in rubygems' "quick" index. The proxy object is to
  # be seeded with what we're given from the source's abbreviated index - the
  # full specification will only be fetched when necesary.
  class LazySpecification
    attr_reader :name, :version
    attr_accessor :source

    def initialize(name, version)
      @name     = name
      @version  = version
    end
  end
end