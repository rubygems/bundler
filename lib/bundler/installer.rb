require 'erb'
require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    class << self
      attr_accessor :post_install_messages
    end

    def self.install(root, definition, options = {})
      installer = new(root, definition)
      installer.run(options)
      installer
    end

    def run(options)
      # Create the BUNDLE_PATH directory
      begin
        Bundler.bundle_path.mkpath unless Bundler.bundle_path.exist?
      rescue Errno::EEXIST
        raise PathError, "Could not install to path `#{Bundler.settings[:path]}` " +
          "because of an invalid symlink. Remove the symlink so the directory can be created."
      end

      if Bundler.settings[:frozen]
        @definition.ensure_equivalent_gemfile_and_lockfile(options[:deployment])
      end

      if dependencies.empty?
        Bundler.ui.warn "The Gemfile specifies no dependencies"
        lock
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

      # Must install gems in the order that the resolver provides
      # as dependencies might actually affect the installation of
      # the gem.
      Installer.post_install_messages = {}
      specs.each do |spec|
        Bundler::Fetcher.fetch(spec) if spec.source.is_a?(Bundler::Source::Rubygems)

        # unless requested_specs.include?(spec)
        #   Bundler.ui.debug "  * Not in requested group; skipping."
        #   next
        # end

        Bundler.rubygems.with_build_args [Bundler.settings["build.#{spec.name}"]] do
          spec.source.install(spec)
          Bundler.ui.debug "from #{spec.loaded_from} "
        end

        Bundler.ui.info ""
        generate_bundler_executable_stubs(spec) if Bundler.settings[:bin]
        FileUtils.rm_rf(Bundler.tmp)
      end

      lock
      generate_standalone(options[:standalone]) if options[:standalone]
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

    def generate_standalone(groups)
      path = Bundler.settings[:path]
      bundler_path = File.join(path, "bundler")
      FileUtils.mkdir_p(bundler_path)

      paths = []

      if groups.empty?
        specs = Bundler.definition.requested_specs
      else
        specs = Bundler.definition.specs_for groups.map { |g| g.to_sym }
      end

      specs.each do |spec|
        next if spec.name == "bundler"

        spec.require_paths.each do |path|
          full_path = File.join(spec.full_gem_path, path)
          paths << Pathname.new(full_path).relative_path_from(Bundler.root.join("bundle/bundler"))
        end
      end


      File.open File.join(bundler_path, "setup.rb"), "w" do |file|
        file.puts "path = File.expand_path('..', __FILE__)"
        paths.each do |path|
          file.puts %{$:.unshift File.expand_path("\#{path}/#{path}")}
        end
      end
    end
  end
end
