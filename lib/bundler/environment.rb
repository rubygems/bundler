require "rubygems/source_index"

module Bundler
  class DefaultManifestNotFound < StandardError; end
  class InvalidCacheArgument < StandardError; end
  class SourceNotCached < StandardError; end

  class Environment
    attr_reader :filename, :dependencies
    attr_accessor :rubygems, :system_gems
    attr_writer :gem_path, :bindir

    def self.load(gemfile = nil)
      gemfile = gemfile ? Pathname.new(gemfile).expand_path : default_manifest_file

      unless gemfile.file?
        raise ManifestFileNotFound, "#{filename.inspect} does not exist"
      end

      new(gemfile)
    end

    def self.default_manifest_file
      current = Pathname.new(Dir.pwd)

      until current.root?
        filename = current.join("Gemfile")
        return filename if filename.exist?
        current = current.parent
      end

      raise DefaultManifestNotFound
    end

    def initialize(filename) #, sources, dependencies, bindir, path, rubygems, system_gems)
      @filename         = filename
      @default_sources  = [GemSource.new(:uri => "http://gems.rubyforge.org"), SystemGemSource.instance]
      @sources          = []
      @priority_sources = []
      @dependencies     = []
      @rubygems         = true
      @system_gems      = true

      # Evaluate the Gemfile
      builder = Dsl.new(self)
      builder.instance_eval(File.read(filename), filename)
    end

    def install(options = {})
      update = options[:update]
      cached = options[:cached]

      no_bundle = dependencies.select { |dep| !dep.bundle }

      repository.install(gem_dependencies, sources,
        :rubygems    => rubygems,
        :system_gems => system_gems,
        :manifest    => filename,
        :update      => update,
        :cached      => cached,
        :no_bundle   => no_bundle.map { |dep| dep.name }
      )
      Bundler.logger.info "Done."
    end

    def cache(options = {})
      gemfile = options[:cache]

      if File.extname(gemfile) == ".gem"
        if !File.exist?(gemfile)
          raise InvalidCacheArgument, "'#{gemfile}' does not exist."
        end
        repository.cache(gemfile)
      elsif File.directory?(gemfile) || gemfile.include?('/')
        if !File.directory?(gemfile)
          raise InvalidCacheArgument, "'#{gemfile}' does not exist."
        end
        gemfiles = Dir["#{gemfile}/*.gem"]
        if gemfiles.empty?
          raise InvalidCacheArgument, "'#{gemfile}' contains no gemfiles"
        end
        repository.cache(*gemfiles)
      else
        local = Gem::SourceIndex.from_installed_gems.find_name(gemfile).last

        if !local
          raise InvalidCacheArgument, "w0t? '#{gemfile}' means nothing to me."
        end

        gemfile = Pathname.new(local.loaded_from)
        gemfile = gemfile.dirname.join('..', 'cache', "#{local.full_name}.gem").expand_path
        repository.cache(gemfile)
      end
    end

    def prune(options = {})
      repository.prune(gem_dependencies, sources)
    end

    def list(options = {})
      Bundler.logger.info "Currently bundled gems:"
      repository.gems.each do |spec|
        Bundler.logger.info " * #{spec.name} (#{spec.version})"
      end
    end

    def setup_environment
      unless system_gems
        ENV["GEM_HOME"] = gem_path
        ENV["GEM_PATH"] = gem_path
      end
      ENV["PATH"]     = "#{bindir}:#{ENV["PATH"]}"
      ENV["RUBYOPT"]  = "-r#{gem_path}/environment #{ENV["RUBYOPT"]}"
    end

    def require_env(env = nil)
      dependencies.each { |d| d.require_env(env) }
    end

    def root
      filename.parent
    end

    def gem_path
      @gem_path ||= root.join("vendor", "gems")
    end

    def bindir
      @bindir ||= root.join("bin")
    end

    def sources
      @priority_sources + @sources + @default_sources
    end

    def add_source(source)
      @sources << source
    end

    def add_priority_source(source)
      @priority_sources << source
    end

    def clear_sources
      @sources.clear
      @default_sources.clear
    end

  private

    def repository
      @repository ||= Repository.new(gem_path, bindir)
    end

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end
  end
end
