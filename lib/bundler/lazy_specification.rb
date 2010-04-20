require "uri"
require "rubygems/spec_fetcher"

module Bundler
  class LazySpecification
    attr_reader :name, :version, :dependencies

    def initialize(name, version)
      @name         = name
      @version      = version
      @dependencies = []
    end
  end
end