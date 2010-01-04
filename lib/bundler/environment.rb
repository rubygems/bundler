require "rubygems/source_index"

module Bundler
  class InvalidCacheArgument < StandardError; end
  class SourceNotCached < StandardError; end

  class Environment
    attr_reader :filename, :dependencies
    attr_accessor :rubygems, :system_gems
    attr_writer :gem_path, :bindir

    def self.default_gem_path(root)
      Pathname.new("#{root}/vendor/gems/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}")
    end

    def initialize(filename)
      @filename         = filename
      @default_sources  = default_sources
      @sources          = []
      @priority_sources = []
      @dependencies     = []
      @rubygems         = true
      @system_gems      = true
    end

    def environment_rb(specs, options)
      load_paths = load_paths_for_specs(specs, options)
      bindir     = @bindir.relative_path_from(gem_path).to_s
      filename   = self.filename.relative_path_from(gem_path).to_s

      template = File.read(File.join(File.dirname(__FILE__), "templates", "environment.erb"))
      erb = ERB.new(template, nil, '-')
      erb.result(binding)
    end

    def require_env(env = nil)
      dependencies.each { |d| d.require_env(env) }
    end

    def root
      filename.parent
    end

    def gem_path
      @gem_path ||= self.class.default_gem_path(root)
    end

    def bindir
      @bindir ||= root.join("bin")
    end

    def sources
      @priority_sources + @sources + @default_sources + [SystemGemSource.instance]
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
      [GemSource.new(:uri => "http://gems.rubyforge.org")]
    end

    def repository
      @repository ||= Bundle.new(self)
    end

    def load_paths_for_specs(specs, options)
      load_paths = []
      specs.each do |spec|
        next if options[:no_bundle].include?(spec.name)
        full_gem_path = Pathname.new(spec.full_gem_path)
        
        load_paths << load_path_for(full_gem_path, spec.bindir) if spec.bindir
        spec.require_paths.each do |path|
          load_paths << load_path_for(full_gem_path, path)
        end
      end
      load_paths
    end

    def load_path_for(gem_path, path)
      gem_path.join(path).relative_path_from(self.gem_path).to_s
    end

    def spec_file_for(spec)
      spec.loaded_from.relative_path_from(self.gem_path).to_s
    end
  end
end
