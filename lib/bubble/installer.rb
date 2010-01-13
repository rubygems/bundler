require 'rubygems/dependency_installer'

module Bubble
  class Installer
    def self.install(definition)
      new(definition).run
    end

    def initialize(definition)
      @definition = definition
    end

    def run
      specs.each do |spec|
        spec.source.install spec
      end
    end

    def dependencies
      @definition.dependencies
    end

    def specs
      @specs ||= begin
        index = Index.new
        sources.reverse_each do |source|
          index.merge!(source.specs)
        end
        Resolver.resolve(dependencies, index)
      end
    end

  private

    def sources
      @definition.sources
    end

  end
end