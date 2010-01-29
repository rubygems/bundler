require 'rubygems/dependency_installer'

module Bundler
  class Installer
    def self.install(root, definition, options)
      new(root, definition).run(options)
    end

    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

    def run(options)
      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        return
      end

      without = options[:without] ? options[:without].map {|w| w.to_sym } : []

      specs.each do |spec|
        next unless spec.source.respond_to?(:install)
        next if (spec.groups & without).any?
        spec.source.install(spec)
      end

      Bundler.ui.confirm "You have bundles. Now, go have fun."
    end

    def dependencies
      @definition.actual_dependencies
    end

    def specs
      @specs ||= group_specs(resolve_locally || resolve_remotely)
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

    def group_specs(specs)
      dependencies.each do |d|
        spec = specs.find { |s| s.name == d.name }
        group_spec(specs, spec, d.group)
      end
      specs
    end

    def group_spec(specs, spec, group)
      spec.groups << group
      spec.groups.uniq!
      spec.dependencies.each do |d|
        spec = specs.find { |s| s.name == d.name }
        group_spec(specs, spec, group)
      end
    end

    def unambiguous?(dep)
      dep.version_requirements.requirements.all? { |op,_| op == '=' }
    end

    def index
      @index ||= begin
        index = local_index

        sources.each do |source|
          specs = source.specs
          Bundler.ui.info "Source: Processing index... "
          index = specs.merge(index)
          Bundler.ui.info "Done."
        end

        index
      end
    end

    def local_index
      @local_index ||= begin
        index = Index.from_installed_gems

        if File.directory?("#{root}/vendor/cache")
          index = cache_source.specs.merge(index)
        end

        index
      end
    end

    def cache_source
      Source::GemCache.new(:path => "#{root}/vendor/cache")
    end

  end
end