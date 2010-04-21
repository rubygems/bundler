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

    def satisfies?(dependency)
      @name == dependency.name && dependency.requirement.satisfied_by?(Gem::Version.new(@version))
    end
  end
end