module Bubble
  class Environment
    def initialize(definition)
      @definition = definition
    end

    def setup
      # Activate the specs
      specs.each do |spec|
        $LOAD_PATH.unshift *spec.load_paths
        Gem.loaded_specs[spec.name] = spec
      end
      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        alias require gem_original_require
        def gem(*)
          # Silently ignore calls to gem
        end
      end
      self
    end

    def dependencies
      @definition.dependencies
    end

    def lock
      yml = details.to_yaml
      File.open("#{Definition.default_gemfile.dirname}/omg.yml", 'w') do |f|
        f.puts yml
      end
    end

    def specs
      @specs ||= Resolver.resolve(@definition.actual_dependencies, index)
    end

    def index
      @index ||= begin
        index = Index.new
        sources.reverse_each do |source|
          index.merge! source.local_specs
        end
        index
      end
    end

  private

    def sources
      @definition.sources
    end

    def details
      details = {}
      details["sources"] = sources.map { |s| { s.class.name.split("::").last => s.options} }
      details["specs"] = specs.map { |s| {s.name => s.version.to_s} }
      details["dependencies"] = dependencies.map { |d| {d.name => d.version_requirements.to_s} }
      details
    end

  end
end