module Bubble
  class Dsl
    def self.evaluate(gemfile, definition)
      builder = new(definition)
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      definition
    end

    def initialize(definition)
      @definition = definition
    end

    def gem(name, *args)
      options = Hash === args.last ? args.pop : {}
      version = args.last || ">= 0"

      @definition.dependencies << Dependency.new(name, version, options)
    end
  end
end