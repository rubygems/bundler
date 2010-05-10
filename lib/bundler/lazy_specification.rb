require "uri"
require "rubygems/spec_fetcher"

module Bundler
  class LazySpecification
    attr_reader :name, :version, :dependencies
    attr_accessor :source

    def initialize(name, version)
      @name         = name
      @version      = version
      @dependencies = []
      @source       = nil
    end

    def satisfies?(dependency)
      @name == dependency.name && dependency.requirement.satisfied_by?(Gem::Version.new(@version))
    end
  end
end