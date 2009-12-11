require "rubygems/source_index"

module Bundler
  class InvalidCacheArgument < StandardError; end
  class SourceNotCached < StandardError; end

  class Environment
    attr_reader :filename, :dependencies
    attr_accessor :rubygems, :system_gems
    attr_writer :gem_path, :bindir

    def initialize(filename)
      @filename         = filename
      @default_sources  = default_sources
      @sources          = []
      @priority_sources = []
      @dependencies     = []
      @rubygems         = true
      @system_gems      = true
    end

    def install(options = {})
      if only_envs = options[:only]
        dependencies.reject! { |d| !only_envs.any? {|env| d.in?(env) } }
      end

      no_bundle = dependencies.map do |dep|
        dep.source == SystemGemSource.instance && dep.name
      end.compact

      update = options[:update]
      cached = options[:cached]

      repository.install(dependencies, sources,
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

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end

  private

    def default_sources
      [GemSource.new(:uri => "http://gems.rubyforge.org"), SystemGemSource.instance]
    end

    def repository
      @repository ||= Bundle.new(self)
    end
  end
end
