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
        inst = Gem::DependencyInstaller.new(:ignore_dependencies => true)
        inst.install spec.name, spec.version
      end
    end

    def dependencies
      @definition.dependencies
    end

    def specs
      @specs ||= Resolver.resolve(dependencies, sources)
    end

  private

    def sources
      @sources ||= Gem.sources.map { |s| Source::Rubygems.new(:uri => s) }
    end

  end
end