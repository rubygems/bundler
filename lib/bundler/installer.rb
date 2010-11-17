require 'erb'
require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    def self.install(root, definition, options = {})
      installer = new(root, definition)
      installer.run(options)
      installer
    end

    def run(options)
      if Bundler.settings[:frozen]
        @definition.ensure_equivalent_gemfile_and_lockfile
      end

      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        return
      end

      if Bundler.default_lockfile.exist? && !options["update"]
        begin
          tmpdef = Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
          local = true unless tmpdef.new_platform? || tmpdef.missing_specs.any?
        rescue BundlerError
        end
      end

      # Since we are installing, we can resolve the definition
      # using remote specs
      unless local
        options["local"] ?
          @definition.resolve_with_cache! :
          @definition.resolve_remotely!
      end

      # Ensure that BUNDLE_PATH exists
      Bundler.mkdir_p(Bundler.bundle_path) unless File.exist?(Bundler.bundle_path)

      # Must install gems in the order that the resolver provides
      # as dependencies might actually affect the installation of
      # the gem.
      specs.each do |spec|
        spec.source.fetch(spec) if spec.source.respond_to?(:fetch)

        # unless requested_specs.include?(spec)
        #   Bundler.ui.debug "  * Not in requested group; skipping."
        #   next
        # end

        begin
          old_args = Gem::Command.build_args
          Gem::Command.build_args = [Bundler.settings["build.#{spec.name}"]]
          spec.source.install(spec)
          Bundler.ui.debug "from #{spec.loaded_from} "
        ensure
          Gem::Command.build_args = old_args
        end

        Bundler.ui.info ""
        generate_bundler_executable_stubs(spec) if Bundler.settings[:bin]
        FileUtils.rm_rf(Bundler.tmp)
      end

      lock
    end

  private

    def generate_bundler_executable_stubs(spec)
      bin_path = Bundler.bin_path
      template = File.read(File.expand_path('../templates/Executable', __FILE__))
      relative_gemfile_path = Bundler.default_gemfile.relative_path_from(bin_path)
      ruby_command = Thor::Util.ruby_command

      spec.executables.each do |executable|
        next if executable == "bundle"
        File.open "#{bin_path}/#{executable}", 'w', 0755 do |f|
          f.puts ERB.new(template, nil, '-').result(binding)
        end
      end
    end
  end
end
