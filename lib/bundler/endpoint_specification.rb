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

    # needed for standalone, load required_paths from local gemspec
    # after the gem in installed
    def require_paths
      if _local_specification
        _local_specification.require_paths
      else
        super
      end
    end

    def _local_specification
      eval(File.read(local_specification_path)) if @loaded_from && File.exists?(local_specification_path)
    end

    private
    def local_specification_path
      "#{installation_path}/specifications/#{full_name}.gemspec"
    end
  end
end
