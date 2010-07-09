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
      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        return
      end

      # Since we are installing, we can resolve the definition
      # using remote specs
      options["local"] ?
        @definition.resolve_with_cache! :
        @definition.resolve_remotely!

      # Ensure that BUNDLE_PATH exists
      Bundler.mkdir_p(Bundler.bundle_path)

      # Must install gems in the order that the resolver provides
      # as dependencies might actually affect the installation of
      # the gem.
      specs.each do |spec|
        spec.source.fetch(spec) if spec.source.respond_to?(:fetch)

        # unless requested_specs.include?(spec)
        #   Bundler.ui.debug "  * Not in requested group; skipping."
        #   next
        # end

        spec.source.install(spec)
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

      spec.executables.each do |executable|
        next if executable == "bundle"
        File.open "#{bin_path}/#{executable}", 'w', 0755 do |f|
          f.puts ERB.new(template, nil, '-').result(binding)
        end
      end
    end
  end
end
