require "rubygems/source_index"

module Bundler
  class InvalidCacheArgument < StandardError; end
  class SourceNotCached < StandardError; end

  class Environment
    attr_reader   :dependencies
    attr_accessor :rubygems, :system_gems

    def initialize(bundle)
      @bundle = bundle # TODO: remove this
      @default_sources  = default_sources
      @sources          = []
      @priority_sources = []
      @dependencies     = []
      @rubygems         = true
      @system_gems      = true
    end

    def environment_rb(specs, options)
      load_paths = load_paths_for_specs(specs, options)
      bindir     = @bundle.bindir.relative_path_from(@bundle.gem_path).to_s
      filename   = @bundle.gemfile.relative_path_from(@bundle.gem_path).to_s

      template = File.read(File.join(File.dirname(__FILE__), "templates", "environment.erb"))
      erb = ERB.new(template, nil, '-')
      erb.result(binding)
    end

    def require_env(env = nil)
      dependencies.each { |d| d.require_env(env) }
    end

    def sources
      @priority_sources + [SystemGemSource.new(@bundle)] + @sources + @default_sources
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

    alias rubygems? rubygems
    alias system_gems? system_gems

  private

    def default_sources
      [GemSource.new(@bundle, :uri => "http://gems.rubyforge.org")]
    end

    def load_paths_for_specs(specs, options)
      load_paths = []
      specs.each do |spec|
        next if spec.no_bundle?
        full_gem_path = Pathname.new(spec.full_gem_path)

        load_paths << load_path_for(full_gem_path, spec.bindir) if spec.bindir
        spec.require_paths.each do |path|
          load_paths << load_path_for(full_gem_path, path)
        end
      end
      load_paths
    end

    def load_path_for(gem_path, path)
      gem_path.join(path).relative_path_from(@bundle.gem_path).to_s
    end

    def spec_file_for(spec)
      spec.loaded_from.relative_path_from(@bundle.gem_path).to_s
    end
  end
end
