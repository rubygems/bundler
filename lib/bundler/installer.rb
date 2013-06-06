require 'erb'
require 'rubygems/dependency_installer'

module Bundler
  class Installer < Environment
    class << self
      attr_accessor :post_install_messages
    end

    # Begins the installation process for Bundler.
    # For more information see the #run method on this class.
    def self.install(root, definition, options = {})
      installer = new(root, definition)
      installer.run(options)
      installer
    end


    def make_bundle_path
      # Create the BUNDLE_PATH directory
      begin
        Bundler.bundle_path.mkpath unless Bundler.bundle_path.exist?
      rescue Errno::EEXIST
        raise PathError, "Could not install to path `#{Bundler.settings[:path]}` " +
          "because of an invalid symlink. Remove the symlink so the directory can be created."
      end
    end


    # Check that the gemfile and lockfile match if we're installing "frozen."
    def vet_freeze!(options)
      if Bundler.settings[:frozen]
        @definition.ensure_equivalent_gemfile_and_lockfile(options[:deployment])
      end
    end


    def install(options)
      # Must install gems in the order that the resolver provides
      # as dependencies might actually affect the installation of
      # the gem.
      Installer.post_install_messages = {}
      specs.each do |spec|
        install_gem_from_spec(spec, options[:standalone])
      end

      generate_standalone(options[:standalone]) if options[:standalone]
    end


    def run(options)
      make_bundle_path
      vet_freeze!(options)

      install(options)
    end


    def install_gem_from_spec(spec, standalone = false)
      # Download the gem to get the spec, because some specs that are returned
      # by rubygems.org are broken and wrong.
      Bundler::Fetcher.fetch(spec) if spec.source.is_a?(Bundler::Source::Rubygems)

      # Fetch the build settings, if there are any
      settings = Bundler.settings["build.#{spec.name}"]
      Bundler.rubygems.with_build_args [settings] do
        spec.source.install(spec)
        Bundler.ui.debug "from #{spec.loaded_from} "
      end

      # newline comes after installing, some gems say "with native extensions"
      Bundler.ui.info ""
      if Bundler.settings[:bin] && standalone
        generate_standalone_bundler_executable_stubs(spec)
      elsif Bundler.settings[:bin]
        generate_bundler_executable_stubs(spec, :force => true)
      end

      FileUtils.rm_rf(Bundler.tmp)
    rescue Exception => e
      # install hook failed
      raise e if e.is_a?(Bundler::InstallHookError) || e.is_a?(Bundler::SecurityError)

      # other failure, likely a native extension build failure
      Bundler.ui.info ""
      Bundler.ui.warn "#{e.class}: #{e.message}"
      msg = "An error occurred while installing #{spec.name} (#{spec.version}),"
      msg << " and Bundler cannot continue.\nMake sure that `gem install"
      msg << " #{spec.name} -v '#{spec.version}'` succeeds before bundling."
      Bundler.ui.debug e.backtrace.join("\n")
      raise Bundler::InstallError, msg
    end

    def generate_bundler_executable_stubs(spec, options = {})
      if options[:binstubs_cmd] && spec.executables.empty?
        options = {}
        spec.runtime_dependencies.each do |dep|
          bins = Bundler.definition.specs[dep].first.executables
          options[dep.name] = bins unless bins.empty?
        end
        if options.any?
          Bundler.ui.warn "#{spec.name} has no executables, but you may want " +
            "one from a gem it depends on."
          options.each{|name,bins| Bundler.ui.warn "  #{name} has: #{bins.join(', ')}" }
        else
          Bundler.ui.warn "There are no executables for the gem #{spec.name}."
        end
        return
      end

      # double-assignment to avoid warnings about variables that will be used by ERB
      bin_path = bin_path = Bundler.bin_path
      template = template = File.read(File.expand_path('../templates/Executable', __FILE__))
      relative_gemfile_path = relative_gemfile_path = Bundler.default_gemfile.relative_path_from(bin_path)
      ruby_command = ruby_command = Thor::Util.ruby_command

      exists = []
      spec.executables.each do |executable|
        next if executable == "bundle"

        binstub_path = "#{bin_path}/#{executable}"
        if File.exists?(binstub_path) && !options[:force]
          exists << executable
          next
        end

        File.open(binstub_path, 'w', 0755) do |f|
          f.puts ERB.new(template, nil, '-').result(binding)
        end
      end

      if options[:binstubs_cmd] && exists.any?
        case exists.size
        when 1
          Bundler.ui.warn "Skipped #{exists[0]} since it already exists."
        when 2
          Bundler.ui.warn "Skipped #{exists.join(' and ')} since they already exist."
        else
          items = exists[0...-1].empty? ? nil : exists[0...-1].join(', ')
          skipped = [items, exists[-1]].compact.join(' and ')
          Bundler.ui.warn "Skipped #{skipped} since they already exist."
        end
        Bundler.ui.warn "If you want to overwrite skipped stubs, use --force."
      end
    end

  private

    def generate_standalone_bundler_executable_stubs(spec)
      # double-assignment to avoid warnings about variables that will be used by ERB
      bin_path = Bundler.bin_path
      template = File.read(File.expand_path('../templates/Executable.standalone', __FILE__))
      ruby_command = ruby_command = Thor::Util.ruby_command

      spec.executables.each do |executable|
        next if executable == "bundle"
        standalone_path = standalone_path = Pathname(Bundler.settings[:path]).expand_path.relative_path_from(bin_path)
        executable_path = executable_path = Pathname(spec.full_gem_path).join(spec.bindir, executable).relative_path_from(bin_path)
        File.open "#{bin_path}/#{executable}", 'w', 0755 do |f|
          f.puts ERB.new(template, nil, '-').result(binding)
        end
      end
    end


    def generate_standalone(groups)
      standalone_path = Bundler.settings[:path]
      bundler_path = File.join(standalone_path, "bundler")
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
          gem_path = Pathname.new(full_path).relative_path_from(Bundler.root.join(bundler_path))
          paths << gem_path.to_s.sub("#{SystemRubyVersion.new.engine}/#{RbConfig::CONFIG['ruby_version']}", '#{ruby_engine}/#{ruby_version}')
        end
      end


      File.open File.join(bundler_path, "setup.rb"), "w" do |file|
        file.puts "require 'rbconfig'"
        file.puts "# ruby 1.8.7 doesn't define RUBY_ENGINE"
        file.puts "ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'"
        file.puts "ruby_version = RbConfig::CONFIG[\"ruby_version\"]"
        file.puts "path = File.expand_path('..', __FILE__)"
        paths.each do |path|
          file.puts %{$:.unshift File.expand_path("\#{path}/#{path}")}
        end
      end
    end
  end
end
