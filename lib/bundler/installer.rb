require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    def self.install(root, definition, options)
      installer = new(root, definition)
      installer.run(options)
      installer
    end

    def run(options)
      if dependencies.empty?
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

        if [Source::Rubygems].include?(spec.source.class)
          Bundler.ui.info "Installing #{spec.name} (#{spec.version}) from #{spec.source}"
        else
          Bundler.ui.info "Using #{spec.name} (#{spec.version}) from #{spec.source}"
        end
        spec.source.install(spec)
      end

      lock
    end

    def specs
      @definition.remote_specs
    end
  end
end
