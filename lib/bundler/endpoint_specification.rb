require 'uri'

module Bundler
  # used for Creating Specifications from the Gemcutter Endpoint
  class EndpointSpecification < Gem::Specification
    include MatchPlatform

    attr_reader :name, :version, :platform, :dependencies
    attr_accessor :source

    def initialize(name, version, platform, dependencies)
      @name         = name
      @version      = version
      @platform     = platform
      @dependencies = dependencies
    end

    def fetch_platform
      @plaftorm
    end
  end
end
