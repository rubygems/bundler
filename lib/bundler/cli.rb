$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bundler
  class CLI < Thor
    def initialize(*)
      super
      use_shell = options["no-color"] ? Thor::Shell::Basic.new : shell

      Bundler.ui = UI::Shell.new(use_shell)
      Gem::DefaultUserInteraction.ui = UI::RGProxy.new(Bundler.ui)
    end

    check_unknown_options! unless ARGV.include?("exec") || ARGV.include?("config")

    default_task :install
    class_option "no-color", :type => :boolean, :banner => "Disable colorization in output"

    desc "init", "Generates a Gemfile into the current working directory"
    long_desc <<-D
      Init generates a default Gemfile in the current working directory. When adding a
      Gemfile to a gem with a gemspec, the --gemspec option will automatically add each
      dependency listed in the gemspec file to the newly created Gemfile.
    D
    method_option "gemspec", :type => :string, :banner => "Use the specified .gemspec to create the Gemfile"
    def init
      opts = options.dup
      if File.exist?("Gemfile")
        Bundler.ui.error "Gemfile already exists at #{Dir.pwd}/Gemfile"
        exit 1
      end

      if opts[:gemspec]
        gemspec = File.expand_path(opts[:gemspec])
        unless File.exist?(gemspec)
          Bundler.ui.error "Gem specification #{gemspec} doesn't exist"
          exit 1
        end
        spec = Gem::Specification.load(gemspec)
        puts "Writing new Gemfile to #{Dir.pwd}/Gemfile"
        File.open('Gemfile', 'w') do |file|
          file << "# Generated from #{gemspec}\n"
          file << spec.to_gemfile
        end
      else
        puts "Writing new Gemfile to #{Dir.pwd}/Gemfile"
        FileUtils.cp(File.expand_path('../templates/Gemfile', __FILE__), 'Gemfile')
      end
    end

    desc "check", "Checks if the dependencies listed in Gemfile are satisfied by currently installed gems"
    long_desc <<-D
      Check searches the local machine for each of the gems requested in the Gemfile. If
      all gems are found, Bundler prints a success message and exits with a status of 0.
      If not, the first missing gem is listed and Bundler exits status 1.
    D
    def check
      not_installed = Bundler.definition.missing_specs

      if not_installed.any?
        Bundler.ui.error "The following gems are missing"
        not_installed.each { |s| Bundler.ui.error " * #{s.name} (#{s.version})" }
        Bundler.ui.warn "Install missing gems with `bundle install`"
        exit 1
      else
        Bundler.ui.info "The Gemfile's dependencies are satisfied"
      end
    end

    desc "install", "Install the current environment to the system"
    long_desc <<-D
      Install will install all of the gems in the current bundle, making them available
      for use. In a freshly checked out repository, this command will give you the same
      gem versions as the last person who updated the Gemfile and ran `bundle update`.

      Passing [DIR] to install (e.g. vendor) will cause the unpacked gems to be installed
      into the [DIR] directory rather than into system gems.

      If the bundle has already been installed, bundler will tell you so and then exit.
    D
    method_option "without", :type => :array, :banner =>
      "Exclude gems that are part of the specified named group."
    method_option "disable-shared-gems", :type => :boolean, :banner =>
      "Do not use any shared gems, such as the system gem repository."
    method_option "gemfile", :type => :string, :banner =>
      "Use the specified gemfile instead of Gemfile"
    method_option "no-prune", :type => :boolean, :banner =>
      "Don't remove stale gems from the cache."
    method_option "no-cache", :type => :boolean, :banner =>
      "Don't update the existing gem cache."
    method_option "quiet", :type => :boolean, :banner =>
      "Only output warnings and errors."
    method_option "local", :type => :boolean, :banner =>
      "Do not attempt to fetch gems remotely and use the gem cache instead"
    method_option "binstubs", :type => :string, :lazy_default => "bin", :banner =>
      "Generate bin stubs for bundled gems to ./bin"
    def install(path = nil)
      opts = options.dup
      opts[:without] ||= []
      opts[:without].map! { |g| g.to_sym }

      # Can't use Bundler.settings for this because settings needs gemfile.dirname
      ENV['BUNDLE_GEMFILE'] = opts[:gemfile] if opts[:gemfile]
      Bundler.settings[:path] = path if path
      Bundler.settings[:bin] = opts["binstubs"] if opts[:binstubs]
      Bundler.settings[:disable_shared_gems] = '1' if options["disable-shared-gems"] || path
      Bundler.settings.without = opts[:without]
      Bundler.ui.be_quiet! if opts[:quiet]

      Installer.install(Bundler.root, Bundler.definition, opts)
      cache if Bundler.root.join("vendor/cache").exist?
      Bundler.ui.confirm "Your bundle is complete! " +
        "Use `bundle show [gemname]` to see where a bundled gem is installed."
    rescue GemNotFound => e
      if Bundler.definition.no_sources?
        Bundler.ui.warn "Your Gemfile doesn't have any sources. You can add one with a line like 'source :gemcutter'"
      end
      raise e
    end

    desc "update", "update the current environment"
    long_desc <<-D
      Update will install the newest versions of the gems listed in the Gemfile. Use
      update when you have changed the Gemfile, or if you want to get the newest
      possible versions of the gems in the bundle.
    D
    method_option "source", :type => :array, :banner => "Update a specific source (and all gems associated with it)"
    def update(*gems)
      sources = Array(options[:source])

      if gems.empty? && sources.empty?
        # We're doing a full update
        Bundler.definition(true)
      else
        Bundler.definition(:gems => gems, :sources => sources)
      end

      Installer.install Bundler.root, Bundler.definition, "update" => true
      cache if Bundler.root.join("vendor/cache").exist?
      Bundler.ui.confirm "Your bundle is updated! " +
        "Use `bundle show [gemname]` to see where a bundled gem is installed."
    end

    desc "lock", "Locks the bundle to the current set of dependencies, including all child dependencies."
    def lock
      Bundler.ui.warn "Lock is deprecated. Your bundle is now locked whenever you run `bundle install`."
    end

    desc "unlock", "Unlock the bundle. This allows gem versions to be changed."
    def unlock
      Bundler.ui.warn "Unlock is deprecated. To update to newer gem versions, use `bundle update`."
    end

    desc "show [GEM]", "Shows all gems that are part of the bundle, or the path to a given gem"
    long_desc <<-D
      Show lists the names and versions of all gems that are required by your Gemfile.
      Calling show with [GEM] will list the exact location of that gem on your machine.
    D
    def show(gem_name = nil)
      if gem_name
        Bundler.ui.info locate_gem(gem_name)
      else
        Bundler.ui.info "Gems included by the bundle:"
        Bundler.load.specs.sort_by { |s| s.name }.each do |s|
          Bundler.ui.info "  * #{s.name} (#{s.version}#{s.git_version})"
        end
      end
    end
    map %w(list) => "show"

    desc "cache", "Cache all the gems to vendor/cache", :hide => true
    method_option "no-prune",  :type => :boolean, :banner => "Don't remove stale gems from the cache."
    def cache
      Bundler.load.cache
      Bundler.load.prune_cache unless options[:no_prune]
    rescue GemNotFound => e
      Bundler.ui.error(e.message)
      Bundler.ui.warn "Run `bundle install` to install missing gems."
      exit 128
    end

    desc "package", "Locks and then caches all of the gems into vendor/cache"
    method_option "no-prune",  :type => :boolean, :banner => "Don't remove stale gems from the cache."
    long_desc <<-D
      The package command will copy the .gem files for every gem in the bundle into the
      directory ./vendor/cache. If you then check that directory into your source
      control repository, others who check out your source will be able to install the
      bundle without having to download any additional gems.
    D
    def package
      install
      # TODO: move cache contents here now that all bundles are locked
      cache
    end
    map %w(pack) => :package

    desc "exec", "Run the command in context of the bundle"
    long_desc <<-D
      Exec runs a command, providing it access to the gems in the bundle. While using
      bundle exec you can require and call the bundled gems as if they were installed
      into the systemwide Rubygems repository.
    D
    def exec(*)
      ARGV.delete("exec")

      # Set PATH
      paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
      paths.unshift "#{Bundler.bundle_path}/bin"
      ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

      # Set BUNDLE_GEMFILE
      ENV["BUNDLE_GEMFILE"] = Bundler::SharedHelpers.default_gemfile.to_s

      # Set RUBYOPT
      rubyopt = [ENV["RUBYOPT"]].compact
      if rubyopt.empty? || rubyopt.first !~ /-rbundler\/setup/
        rubyopt.unshift "-rbundler/setup"
        rubyopt.unshift "-I#{File.expand_path('../..', __FILE__)}"
        ENV["RUBYOPT"] = rubyopt.join(' ')
      end

      begin
        # Run
        Kernel.exec(*ARGV)
      rescue Errno::EACCES
        Bundler.ui.error "bundler: not executable: #{ARGV.first}"
      rescue Errno::ENOENT
        Bundler.ui.error "bundler: command not found: #{ARGV.first}"
        Bundler.ui.warn  "Install missing gem binaries with `bundle install`"
      end
    end

    desc "config NAME [VALUE]", "retrieve or set a configuration value"
    long_desc <<-D
      Retrieves or sets a configuration value. If only parameter is provided, retrieve the value. If two parameters are provided, replace the
      existing value with the newly provided one.

      By default, setting a configuration value sets it for all projects
      on the machine. If you want to set the configuration for a specific
      project, use the --local flag.

      If a global setting is superceded by local configuration, this command
      will show the current value, as well as any superceded values and
      where they were specified.
    D
    def config(name, *values)
      locations = Bundler.settings.locations(name)

      if values.empty?
        # TODO: Say something more useful here
        locations.each do |location, value|
          if value
            Bundler.ui.info "#{location}: #{value}"
          end
        end
      else
        if local = locations[:local]
          Bundler.ui.info "Your application has set #{name} to #{local.inspect}. This will override the " \
            "system value you are currently setting"
        end

        if global = locations[:global]
          Bundler.ui.info "You are replacing the current system value of #{name}, which is currently #{global}"
        end

        if env = locations[:env]
          Bundler.ui.info "You have set a bundler environment variable for #{env}. This will take precedence " \
            "over the system value you are setting"
        end

        Bundler.settings.set_global(name, values.join(" "))
      end
    end

    desc "open GEM", "Opens the source directory of the given bundled gem"
    def open(name)
      editor = [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find{|e| !e.nil? && !e.empty? }
      if editor
        command = "#{editor} #{locate_gem(name)}"
        success = system(command)
        Bundler.ui.info "Could not run '#{command}'" unless success
      else
        Bundler.ui.info("To open a bundled gem, set $EDITOR or $BUNDLER_EDITOR")
      end
    end

    desc "console [GROUP]", "Opens an IRB session with the bundle pre-loaded"
    def console(group = nil)
      require 'bundler/setup'
      group ? Bundler.require(:default, group) : Bundler.require
      ARGV.clear

      require 'irb'
      IRB.start
    end

    desc "version", "Prints the bundler's version information"
    def version
      Bundler.ui.info "Bundler version #{Bundler::VERSION}"
    end
    map %w(-v --version) => :version

    desc 'viz', "Generates a visual dependency graph"
    long_desc <<-D
      Viz generates a PNG file of the current Gemfile as a dependency graph.
      Viz requires the ruby-graphviz gem (and its dependencies).
      The associated gems must also be installed via 'bundle install'.
    D
    method_option :file, :type => :string, :default => 'gem_graph.png', :aliases => '-f', :banner => "The name to use for the generated png file."
    method_option :version, :type => :boolean, :default => false, :aliases => '-v', :banner => "Set to show each gem version."
    method_option :requirements, :type => :boolean, :default => false, :aliases => '-r', :banner => "Set to show the version of each required dependency."
    def viz
      output_file = File.expand_path(options[:file])
      graph = Graph.new( Bundler.load )

      begin
        graph.viz(output_file, options[:version], options[:requirements])
        Bundler.ui.info output_file
      rescue LoadError => e
        Bundler.ui.error e.inspect
        Bundler.ui.warn "Make sure you have the graphviz ruby gem. You can install it with:"
        Bundler.ui.warn "`gem install ruby-graphviz`"
      rescue StandardError => e
        if e.message =~ /GraphViz not installed or dot not in PATH/
          Bundler.ui.error e.message
          Bundler.ui.warn "The ruby graphviz gem requires GraphViz to be installed"
        else
          raise
        end
      end
    end

  private

    def locate_gem(name)
      spec = Bundler.load.specs.find{|s| s.name == name }
      raise GemNotFound, "Could not find gem '#{name}' in the current bundle." unless spec
      if spec.name == 'bundler'
        return File.expand_path('../../../', __FILE__)
      end
      spec.full_gem_path
    end
  end
end
