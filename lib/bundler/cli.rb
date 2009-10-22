require "optparse"

module Bundler
  class CLI
    def self.run(command, options = {})
      new(options).run(command)
    rescue DefaultManifestNotFound => e
      Bundler.logger.error "Could not find a Gemfile to use"
      exit 3
    rescue InvalidEnvironmentName => e
      Bundler.logger.error "Gemfile error: #{e.message}"
      exit 4
    rescue InvalidRepository => e
      Bundler.logger.error e.message
      exit 5
    rescue VersionConflict => e
      Bundler.logger.error e.message
      exit 6
    rescue GemNotFound => e
      Bundler.logger.error e.message
      exit 7
    rescue InvalidCacheArgument => e
      Bundler.logger.error e.message
      exit 8
    rescue SourceNotCached => e
      Bundler.logger.error e.message
      exit 9
    rescue ManifestFileNotFound => e
      Bundler.logger.error e.message
      exit 10
    end

    def initialize(options)
      @options = options
      @environment = Bundler::Environment.load(@options[:manifest])
    end

    def bundle
      @environment.install(@options)
    end

    def cache
      @environment.cache(@options)
    end

    def prune
      @environment.prune(@options)
    end

    def list
      @environment.list(@options)
    end

    def exec
      @environment.setup_environment
      # w0t?
      super(*$command)
    end

    def run(command)
      send(command)
    end

  end
end
