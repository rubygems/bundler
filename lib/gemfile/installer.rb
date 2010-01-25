require 'rubygems/dependency_installer'

module Gemfile
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
      @definition.actual_dependencies
    end

    def specs
      @specs ||= begin
        Resolver.resolve(dependencies, index)
      end
    end

  private

    def sources
      @definition.sources
    end

    def index
      @index ||= begin
        index = Index.new
        sources.reverse_each do |source|
          index.merge!(source.specs)
        end
        index
      end
    end

  end
end