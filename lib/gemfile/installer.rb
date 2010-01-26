require 'rubygems/dependency_installer'

module Gemfile
  class Installer
    def self.install(root, definition)
      new(root, definition).run
    end

    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

    def run
      specs.each do |spec|
        next unless spec.source.respond_to?(:install)
        spec.source.install(spec)
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
        index = Index.from_installed_gems

        if File.directory?("#{root}/vendor/cache")
          index.merge! Source::GemCache.new(:path => "#{root}/vendor/cache").specs
        end

        sources.reverse_each do |source|
          index.merge!(source.specs)
        end
        index
      end
    end

  end
end