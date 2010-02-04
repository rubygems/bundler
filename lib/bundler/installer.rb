require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    def self.install(root, definition, options)
      new(root, definition).run(options)
    end

    def run(options)
      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        return
      end

      specs.sort_by { |s| s.name }.each do |spec|
        # unless spec.source.is_a?(Source::SystemGems)
          Bundler.ui.info "Installing #{spec.name} (#{spec.version}) from #{spec.source} "
        # end

        if (spec.groups & options[:without]).any?
          Bundler.ui.debug "  * Not in requested group; skipping."
          next
        end
        spec.source.install(spec)
        Bundler.ui.info ""
      end

      Bundler.ui.confirm "Your bundle is complete!"
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
      return if dependencies.any? { |d| ambiguous?(d) }

      source_requirements = {}
      dependencies.each do |dep|
        next unless dep.source && dep.source.respond_to?(:local_specs)
        source_requirements[dep.name] = dep.source.local_specs
      end

      # Run a resolve against the locally available gems
      specs = Resolver.resolve(dependencies, local_index, source_requirements)

      # Simple logic for now. Can improve later.
      specs.length == dependencies.length && specs
    rescue Bundler::GemNotFound
      nil
      raise if ENV["OMG"]
    end

    def resolve_remotely
      index # trigger building the index
      Bundler.ui.info "Resolving dependencies"
      source_requirements = {}
      dependencies.each do |dep|
        next unless dep.source
        source_requirements[dep.name] = dep.source.specs
      end

      specs = Resolver.resolve(dependencies, index, source_requirements)
      specs
    end

    def ambiguous?(dep)
      dep.version_requirements.requirements.any? { |op,_| op != '=' }
    end

    def index
      @index ||= begin
        index = Index.new

        if File.directory?("#{root}/vendor/cache")
          index = cache_source.specs.merge(index).freeze
        end

        rg_sources = sources.select { |s| s.is_a?(Source::Rubygems) }
        other_sources = sources.select { |s| !s.is_a?(Source::Rubygems)   }

        other_sources.each do |source|
          i = source.specs
          Bundler.ui.debug "Source: Processing index"
          index = i.merge(index).freeze
        end

        index = Index.from_installed_gems.merge(index)

        rg_sources.each do |source|
          i = source.specs
          Bundler.ui.debug "Source: Processing index"
          index = i.merge(index).freeze
        end

        index
      end
    end

    def local_index
      @local_index ||= begin
        index = Index.new

        sources.each do |source|
          next unless source.respond_to?(:local_specs)
          index = source.local_specs.merge(index)
        end

        if File.directory?("#{root}/vendor/cache")
          index = cache_source.specs.merge(index).freeze
        end

        Index.from_installed_gems.merge(index)
      end
    end

    def cache_source
      Source::GemCache.new("path" => "#{root}/vendor/cache")
    end

  end
end
