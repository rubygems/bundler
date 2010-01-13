module Bubble
  class Environment
    def initialize(definition)
      @definition = definition
    end

    def setup
      specs.each do |spec|
        $LOAD_PATH.unshift *spec.load_paths
        Gem.loaded_specs[spec.name] = spec
      end
      self
    end

    def dependencies
      @definition.dependencies
    end

    def specs
      @specs ||= Resolver.resolve(dependencies, index)
    end

    def index
      @index ||= begin
        index = Index.new
        @definition.sources.reverse_each do |source|
          index.merge! source.local_specs
        end
        index
      end
    end

  end
end