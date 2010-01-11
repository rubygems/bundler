module Bubble
  class Environment
    def initialize(definition)
      @definition = definition
    end

    def dependencies
      @definition.dependencies
    end

    def gems
      []
    end
  end
end