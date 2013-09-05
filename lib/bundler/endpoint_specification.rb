require "bundler/match_platform"

module Bundler
  # used for Creating Specifications from the Gemcutter Endpoint
  class EndpointSpecification < Gem::Specification
    include MatchPlatform

    attr_reader :name, :version, :platform, :dependencies
    attr_accessor :source, :source_uri
    attr_accessor :required_ruby_version, :required_rubygems_version

    def initialize(name, version, platform, dependencies)
      @name         = name
      @version      = version
      @platform     = platform
      @dependencies = dependencies
    end

    def fetch_platform
      @platform
    end

    # needed for standalone, load required_paths from local gemspec
    # after the gem in installed
    def require_paths
      __specification__ ? __specification__.require_paths : super
    end

    # needed for binstubs
    def executables
      __specification__ ? __specification__.executables : super
    end

    # needed for bundle clean
    def bindir
      __specification__ ? __specification__.bindir : super
    end

    # needed for post_install_messages during install
    def post_install_message
      __specification__ && __specification__.post_install_message
    end

    def __specification__
      return @remote_specification if @remote_specification
      return @specification if defined?(@specification)

      if @loaded_from && File.exists?(local_specification_path)
        @specification = Bundler.load_gemspec(local_specification_path)
      else
        @specification = nil
      end
    end

    def __swap__(spec)
      @remote_specification = spec
    end

    private
    def local_specification_path
      "#{base_dir}/specifications/#{full_name}.gemspec"
    end
  end
end
