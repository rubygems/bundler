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
      @bundle = Bundle.load(@options[:manifest])
    end

    def bundle
      @bundle.install(@options)
    end

    def cache
      gemfile = @options[:cache]

      if File.extname(gemfile) == ".gem"
        if !File.exist?(gemfile)
          raise InvalidCacheArgument, "'#{gemfile}' does not exist."
        end
        @bundle.cache(gemfile)
      elsif File.directory?(gemfile) || gemfile.include?('/')
        if !File.directory?(gemfile)
          raise InvalidCacheArgument, "'#{gemfile}' does not exist."
        end
        gemfiles = Dir["#{gemfile}/*.gem"]
        if gemfiles.empty?
          raise InvalidCacheArgument, "'#{gemfile}' contains no gemfiles"
        end
        @bundle.cache(*gemfiles)
      else
        raise InvalidCacheArgument, "w0t? '#{gemfile}' means nothing to me."
      end
    end

    def prune
      @bundle.prune(@options)
    end

    def list
      @bundle.list(@options)
    end

    def list_outdated
      @bundle.list_outdated(@options)
    end

    def exec
      @bundle.setup_environment
      # w0t?
      super(*$command)
    end

    def run(command)
      send(command)
    end

  end
end
