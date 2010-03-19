require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    def self.install(root, definition, options)
      new(root, definition).run(options)
    end

    def run(options)
      if actual_dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        return
      end

      # Ensure that BUNDLE_PATH exists
      FileUtils.mkdir_p(Bundler.bundle_path)

      # Must install gems in the order that the resolver provides
      # as dependencies might actually affect the installation of
      # the gem.
      specs.each do |spec|
        spec.source.fetch(spec) if spec.source.respond_to?(:fetch)

        unless requested_specs.include?(spec)
          Bundler.ui.debug "  * Not in requested group; skipping."
          next
        end

        Bundler.ui.info "Installing #{spec.name} (#{spec.version}) from #{spec.source} "

        spec.source.install(spec)

        Bundler.ui.info ""
      end

      if locked?
        write_rb_lock
      end

      Bundler.ui.confirm "Your bundle is complete!"
    end

    def dependencies
      @definition.dependencies
    end

    def actual_dependencies
      @definition.actual_dependencies
    end

  private

    def sources
      @definition.sources
    end

    def resolve_locally
      # Return unless all the dependencies have = version requirements
      return if actual_dependencies.any? { |d| ambiguous?(d) }

      specs = super

      # Simple logic for now. Can improve later.
      specs.length == actual_dependencies.length && specs
    rescue GemNotFound, PathError => e
      nil
    end

    def resolve_remotely
      resolve(:specs, remote_index)
    end

    def ambiguous?(dep)
      dep.requirement.requirements.any? { |op,_| op != '=' }
    end

    def remote_index
      @remote_index ||= Index.build do |idx|
        rubygems, other = sources.partition { |s| Source::Rubygems === s }

        other.each do |source|
          Bundler.ui.debug "Source: Processing index"
          idx.use source.specs
        end

        idx.use Index.installed_gems
        idx.use Index.cached_gems

        rubygems.each do |source|
          Bundler.ui.debug "Source: Processing index"
          idx.use source.specs
        end
      end
    end
  end
end
