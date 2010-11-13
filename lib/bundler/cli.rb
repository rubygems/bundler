$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'thor/actions'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bundler
  class CLI < Thor
    include Thor::Actions

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      Bundler.ui = UI::Shell.new(the_shell)
      Bundler.ui.debug! if options["verbose"]
      Gem::DefaultUserInteraction.ui = UI::RGProxy.new(Bundler.ui)
    end

    check_unknown_options! unless ARGV.include?("exec") || ARGV.include?("config")

    default_task :install
    class_option "no-color", :type => :boolean, :banner => "Disable colorization in output"
    class_option "verbose",  :type => :boolean, :banner => "Enable verbose output mode", :aliases => "-V"

    def help(cli = nil)
      case cli
      when "gemfile" then command = "gemfile.5"
      when nil       then command = "bundle"
      else command = "bundle-#{cli}"
      end

      manpages = %w(
          bundle
          bundle-config
          bundle-exec
          bundle-install
          bundle-package
          bundle-update
          gemfile.5)

      if manpages.include?(command)
        root = File.expand_path("../man", __FILE__)

        if have_groff? && root !~ %r{^file:/.+!/META-INF/jruby.home/.+}
          groff   = "groff -Wall -mtty-char -mandoc -Tascii"
          pager   = ENV['MANPAGER'] || ENV['PAGER'] || 'more'

          Kernel.exec "#{groff} #{root}/#{command} | #{pager}"
        else
          puts File.read("#{root}/#{command}.txt")
        end
      else
        super
      end
    end

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
        File.open('Gemfile', 'wb') do |file|
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
    method_option "gemfile", :type => :string, :banner =>
      "Use the specified gemfile instead of Gemfile"
    def check
      ENV['BUNDLE_GEMFILE'] = File.expand_path(options[:gemfile]) if options[:gemfile]
      begin
        not_installed = Bundler.definition.missing_specs
      rescue GemNotFound, VersionConflict
        Bundler.ui.error "Your Gemfile's dependencies could not be satisfied"
        Bundler.ui.warn  "Install missing gems with `bundle install`"
        exit 1
      end

      if not_installed.any?
        Bundler.ui.error "The following gems are missing"
        not_installed.each { |s| Bundler.ui.error " * #{s.name} (#{s.version})" }
        Bundler.ui.warn "Install missing gems with `bundle install`"
        exit 1
      else
        Bundler.load.lock
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
      "This option is deprecated. Please do not use it."
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
    method_option "path", :type => :string, :banner =>
      "Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine"
    method_option "system", :type => :boolean, :banner =>
      "Install to the system location ($BUNDLE_PATH or $GEM_HOME) even if the bundle was previously installed somewhere else for this application"
    method_option "frozen", :type => :boolean, :banner =>
      "Do not allow the Gemfile.lock to be updated after this install"
    method_option "deployment", :type => :boolean, :banner =>
      "Install using defaults tuned for deployment environments"
    method_option "production", :type => :boolean, :banner =>
      "Deprecated, please use --deployment instead"
    def install(path = nil)
      opts = options.dup
      opts[:without] ||= []
      if opts[:without].size == 1
        opts[:without].map!{|g| g.split(" ") }
        opts[:without].flatten!
      end
      opts[:without].map!{|g| g.to_sym }

      ENV['BUNDLE_GEMFILE'] = File.expand_path(opts[:gemfile]) if opts[:gemfile]
      ENV['RB_USER_INSTALL'] = '1' if Bundler::FREEBSD

      # Just disable color in deployment mode
      Bundler.ui.shell = Thor::Shell::Basic.new if opts[:deployment]

      if opts[:production]
        opts[:deployment] = true
        Bundler.ui.warn "The --production option is deprecated, and will be removed in " \
                        "the final release of Bundler 1.0. Please use --deployment instead."
      end

      if (path || opts[:path] || opts[:deployment]) && opts[:system]
        Bundler.ui.error "You have specified both a path to install your gems to, \n" \
                         "as well as --system. Please choose."
        exit 1
      end

      if path && opts[:path]
        Bundler.ui.error "You have specified a path via `bundle install #{path}` as well as\n" \
                         "by `bundle install --path #{options[:path]}`. These options are\n" \
                         "equivalent, so please use one or the other."
        exit 1
      end

      if opts["disable-shared-gems"]
        Bundler.ui.error "The disable-shared-gem option is no longer available.\n\n" \
                         "Instead, use `bundle install` to install to your system,\n" \
                         "or `bundle install --path path/to/gems` to install to an isolated\n" \
                         "location. Bundler will resolve relative paths relative to\n" \
                         "your `Gemfile`."
        exit 1
      end

      if opts[:deployment] || opts[:frozen]
        unless Bundler.default_lockfile.exist?
          flag = opts[:deployment] ? '--deployment' : '--frozen'
          raise ProductionError, "The #{flag} flag requires a Gemfile.lock. Please make " \
                                 "sure you have checked your Gemfile.lock into version control " \
                                 "before deploying."
        end

        if Bundler.root.join("vendor/cache").exist?
          opts[:local] = true
        end

        Bundler.settings[:frozen] = '1'
      end

      # Can't use Bundler.settings for this because settings needs gemfile.dirname
      Bundler.settings[:path] = nil if opts[:system]
      Bundler.settings[:path] = "vendor/bundle" if opts[:deployment]
      Bundler.settings[:path] = path if path
      Bundler.settings[:path] = opts[:path] if opts[:path]
      Bundler.settings[:bin] = opts["binstubs"] if opts[:binstubs]
      Bundler.settings[:disable_shared_gems] = '1' if Bundler.settings[:path]
      Bundler.settings.without = opts[:without] unless opts[:without].empty?
      Bundler.ui.be_quiet! if opts[:quiet]

      Installer.install(Bundler.root, Bundler.definition, opts)
      Bundler.load.cache if Bundler.root.join("vendor/cache").exist?

      if Bundler.settings[:path]
        relative_path = Bundler.settings[:path]
        relative_path = "./" + relative_path unless relative_path[0] == ?/
        Bundler.ui.confirm "Your bundle is complete! " +
          "It was installed into #{relative_path}"
      else
        Bundler.ui.confirm "Your bundle is complete! " +
          "Use `bundle show [gemname]` to see where a bundled gem is installed."
      end

      if path
        Bundler.ui.warn "The path argument to `bundle install` is deprecated. " +
          "It will be removed in version 1.1. " +
          "Please use `bundle install --path #{path}` instead."
      end
    rescue GemNotFound => e
      if opts[:local]
        Bundler.ui.warn "Some gems seem to be missing from your vendor/cache directory."
      end

      if Bundler.definition.no_sources?
        Bundler.ui.warn "Your Gemfile doesn't have any sources. You can add one with a line like 'source :rubygems'"
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
      Bundler.load.cache if Bundler.root.join("vendor/cache").exist?
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
      Bundler.load.lock

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
      Bundler.definition.resolve_with_cache!
      Bundler.load.cache
      Bundler.settings[:no_prune] = true if options[:no_prune]
      Bundler.load.lock
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
      Bundler.load.cache
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

      Bundler.setup

      begin
        # Run
        Kernel.exec(*ARGV)
      rescue Errno::EACCES
        Bundler.ui.error "bundler: not executable: #{ARGV.first}"
        exit 126
      rescue Errno::ENOENT
        Bundler.ui.error "bundler: command not found: #{ARGV.first}"
        Bundler.ui.warn  "Install missing gem binaries with `bundle install`"
        exit 127
      end
    end

    desc "config NAME [VALUE]", "retrieve or set a configuration value"
    long_desc <<-D
      Retrieves or sets a configuration value. If only parameter is provided, retrieve the value. If two parameters are provided, replace the
      existing value with the newly provided one.

      By default, setting a configuration value sets it for all projects
      on the machine.

      If a global setting is superceded by local configuration, this command
      will show the current value, as well as any superceded values and
      where they were specified.
    D
    def config(name = nil, *args)
      values = ARGV.dup
      values.shift # remove config
      values.shift # remove the name

      unless name
        Bundler.ui.confirm "Settings are listed in order of priority. The top value will be used.\n"

        Bundler.settings.all.each do |setting|
          Bundler.ui.confirm "#{setting}"
          with_padding do
            Bundler.settings.pretty_values_for(setting).each do |line|
              Bundler.ui.info line
            end
          end
          Bundler.ui.confirm ""
        end
        return
      end

      if values.empty?
        Bundler.ui.confirm "Settings for `#{name}` in order of priority. The top value will be used"
        with_padding do
          Bundler.settings.pretty_values_for(name).each { |line| Bundler.ui.info line }
        end
      else
        locations = Bundler.settings.locations(name)

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
        gem_path = locate_gem(name)
        Dir.chdir(gem_path) do
          command = "#{editor} #{gem_path}"
          success = system(command)
          Bundler.ui.info "Could not run '#{command}'" unless success
        end
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

    desc "gem GEM", "Creates a skeleton for creating a rubygem"
    method_option :bin, :type => :boolean, :default => false, :aliases => '-b', :banner => "Generate a binary for your library."
    def gem(name)
      target = File.join(Dir.pwd, name)
      constant_name = name.split('_').map{|p| p.capitalize}.join
      constant_name = constant_name.split('-').map{|q| q.capitalize}.join('::') if constant_name =~ /-/
      constant_array = constant_name.split('::')
      FileUtils.mkdir_p(File.join(target, 'lib', name))
      opts = {:name => name, :constant_name => constant_name, :constant_array => constant_array}
      template(File.join("newgem/Gemfile.tt"),               File.join(target, "Gemfile"),                opts)
      template(File.join("newgem/Rakefile.tt"),              File.join(target, "Rakefile"),               opts)
      template(File.join("newgem/gitignore.tt"),             File.join(target, ".gitignore"),             opts)
      template(File.join("newgem/newgem.gemspec.tt"),        File.join(target, "#{name}.gemspec"),        opts)
      template(File.join("newgem/lib/newgem.rb.tt"),         File.join(target, "lib/#{name}.rb"),         opts)
      template(File.join("newgem/lib/newgem/version.rb.tt"), File.join(target, "lib/#{name}/version.rb"), opts)
      if options[:bin]
        template(File.join("newgem/bin/newgem.tt"),          File.join(target, 'bin', name),              opts)
      end
      Bundler.ui.info "Initializating git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }
    end

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    end

  private

    def have_groff?
      !(`which groff` rescue '').empty?
    end

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
