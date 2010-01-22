module Bubble
  class Environment
    def initialize(definition)
      @definition = definition
    end

    def setup
      # Has to happen first
      cripple_rubygems

      # Activate the specs
      specs.each do |spec|
        $LOAD_PATH.unshift *spec.load_paths
        Gem.loaded_specs[spec.name] = spec
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

    def cripple_rubygems
      # handle 1.9 where system gems are always on the load path
      if defined?(::Gem)
        $LOAD_PATH.reject! do |p|
          p != File.dirname(__FILE__) &&
            Gem.path.any? { |gp| p.include?(gp) }
        end
      end

      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias require gem_original_require
        end

        def gem(*)
          # Silently ignore calls to gem
        end
      end
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