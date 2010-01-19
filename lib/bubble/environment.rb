module Bubble
  class Environment
    def self.from_gemfile(gemfile)
      new Definition.from_gemfile(gemfile)
    end

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

    def lock
      yml = @definition.to_yaml
      File.open("#{Definition.default_gemfile.dirname}/omg.yml", 'w') do |f|
        f.puts yml
      end
    end

    def specs
      @definition.specs
    end

    def index
      @definition.index
    end

  end
end