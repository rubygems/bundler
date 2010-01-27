require 'rubygems/dependency_installer'

module Bundler
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
      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        return
      end

      specs.each do |spec|
        next unless spec.source.respond_to?(:install)
        spec.source.install(spec)
      end

      Bundler.ui.confirm "You have bundles. Now, go have fun."
    end

    def dependencies
      @definition.actual_dependencies
    end

    def specs
      @specs ||= resolve_locally || resolve_remotely
    end

  private

    def sources
      @definition.sources
    end

    def resolve_locally
      # Return unless all the dependencies have = version requirements
      return unless dependencies.all? { |d| unambiguous?(d) }

      # Run a resolve against the locally available gems
      specs = Resolver.resolve(dependencies, local_index)

      # Simple logic for now. Can improve later.
      specs.length == dependencies.length && specs
    rescue Bundler::GemNotFound
      nil
    end

    def resolve_remotely
      index # trigger building the index
      Bundler.ui.info "Resolving dependencies... "
      specs = Resolver.resolve(dependencies, index)
      Bundler.ui.info "Done."
      specs
    end

    def unambiguous?(dep)
      dep.version_requirements.requirements.all? { |op,_| op == '='  }
    end

    def index
      @index ||= begin
        index = local_index

        if File.directory?("#{root}/vendor/cache")
          index = index.merge Source::GemCache.new(:path => "#{root}/vendor/cache").specs
        end

        sources.reverse_each do |source|
          specs = source.specs
          Bundler.ui.info "Source: Processing index... "
          index = index.merge(specs)
          Bundler.ui.info "Done."
        end

        index
      end
    end

    def local_index
      @local_index ||= begin
        index = Index.from_installed_gems

        if File.directory?("#{root}/vendor/cache")
          index = index.merge Source::GemCache.new(:path => "#{root}/vendor/cache").specs
        end

        index
      end
    end

  end
end