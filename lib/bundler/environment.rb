require "rubygems/source_index"

module Bundler
  class DefaultManifestNotFound < StandardError; end
  class InvalidCacheArgument < StandardError; end
  class SourceNotCached < StandardError; end

  class Environment
    attr_reader :filename, :dependencies
    attr_accessor :rubygems, :system_gems
    attr_writer :gem_path, :bindir

    def self.load(file = nil)
      gemfile = Pathname.new(file || default_manifest_file).expand_path

      unless gemfile.file?
        raise ManifestFileNotFound, "Manifest file not found: #{gemfile.to_s.inspect}"
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

    def initialize(filename)
      @filename         = filename
      @default_sources  = default_sources
      @sources          = []
      @priority_sources = []
      @dependencies     = []
      @rubygems         = true
      @system_gems      = true

      # Evaluate the Gemfile
      Dsl.evaluate(self, filename)
    end

    def install(options = {})
      if only_envs = options[:only]
        dependencies.reject! { |d| !only_envs.any? {|env| d.in?(env) } }
      end

      no_bundle = dependencies.map { |dep| !dep.bundle && dep.name }.compact

      update = options[:update]
      cached = options[:cached]

      repository.install(gem_dependencies, sources,
        :rubygems      => rubygems,
        :system_gems   => system_gems,
        :manifest      => filename,
        :update        => options[:update],
        :cached        => options[:cached],
        :build_options => options[:build_options],
        :no_bundle     => no_bundle
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

    def list_outdated(options={})
      outdated_gems = repository.outdated_gems
      if outdated_gems.empty?
        Bundler.logger.info "All gems are up to date."
      else
        Bundler.logger.info "Outdated gems:"
        outdated_gems.each do |name|
          Bundler.logger.info " * #{name}"
        end
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

    def default_sources
      [GemSource.new(:uri => "http://gems.rubyforge.org"), SystemGemSource.instance]
    end

    def repository
      @repository ||= Repository.new(gem_path, bindir)
    end

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end
  end
end
