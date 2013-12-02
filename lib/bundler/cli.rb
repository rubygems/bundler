require 'bundler'
require 'bundler/cli/init'
require 'bundler/similarity_detector'
require 'bundler/vendored_thor'

module Bundler
  class CLI < Thor
    include Thor::Actions

    def self.start(*)
      super
    rescue Exception => e
      Bundler.ui = UI::Shell.new
      raise e
    end

    def initialize(*)
      super
      ENV['BUNDLE_GEMFILE']   = File.expand_path(options[:gemfile]) if options[:gemfile]
      Bundler::Retry.attempts = options[:retry] || Bundler.settings[:retry] || Bundler::Retry::DEFAULT_ATTEMPTS
      Bundler.rubygems.ui = UI::RGProxy.new(Bundler.ui)
    rescue UnknownArgumentError => e
      raise InvalidOption, e.message
    ensure
      options ||= {}
      Bundler.ui = UI::Shell.new(options)
      Bundler.ui.level = "debug" if options["verbose"]
    end

    check_unknown_options!(:except => [:config, :exec])
    stop_on_unknown_option! :exec

    default_task :install
    class_option "no-color", :type => :boolean, :banner => "Disable colorization in output"
    class_option "verbose",  :type => :boolean, :banner => "Enable verbose output mode", :aliases => "-V"
    class_option "retry",    :type => :numeric, :aliases => "-r", :banner =>
      "Specify the number of times you wish to attempt network commands"

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
          bundle-platform
          gemfile.5)

      if manpages.include?(command)
        root = File.expand_path("../man", __FILE__)

        if Bundler.which("man") && root !~ %r{^file:/.+!/META-INF/jruby.home/.+}
          Kernel.exec "man #{root}/#{command}"
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
      Init.new(options.dup).run
    end

    desc "check", "Checks if the dependencies listed in Gemfile are satisfied by currently installed gems"
    long_desc <<-D
      Check searches the local machine for each of the gems requested in the Gemfile. If
      all gems are found, Bundler prints a success message and exits with a status of 0.
      If not, the first missing gem is listed and Bundler exits status 1.
    D
    method_option "gemfile", :type => :string, :banner =>
      "Use the specified gemfile instead of Gemfile"
    method_option "path", :type => :string, :banner =>
      "Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine"
    method_option "dry-run", :type => :boolean, :default => false, :banner =>
      "Lock the Gemfile"
    def check
      Check.new(options).run
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
    method_option "shebang", :type => :string, :banner =>
      "Specify a different shebang executable name than the default (usually 'ruby')"
    method_option "path", :type => :string, :banner =>
      "Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine"
    method_option "system", :type => :boolean, :banner =>
      "Install to the system location ($BUNDLE_PATH or $GEM_HOME) even if the bundle was previously installed somewhere else for this application"
    method_option "frozen", :type => :boolean, :banner =>
      "Do not allow the Gemfile.lock to be updated after this install"
    method_option "deployment", :type => :boolean, :banner =>
      "Install using defaults tuned for deployment environments"
    method_option "standalone", :type => :array, :lazy_default => [], :banner =>
      "Make a bundle that can work without the Bundler runtime"
    method_option "full-index", :type => :boolean, :banner =>
      "Use the rubygems modern index instead of the API endpoint"
    method_option "clean", :type => :boolean, :banner =>
      "Run bundle clean automatically after install"
    method_option "trust-policy", :alias => "P", :type => :string, :banner =>
      "Gem trust policy (like gem install -P). Must be one of " +
        Bundler.rubygems.security_policies.keys.join('|') unless
        Bundler.rubygems.security_policies.empty?
    method_option "jobs", :aliases => "-j", :type => :numeric, :banner =>
      "Specify the number of jobs to run in parallel"

    def install
      Install.new(options.dup).run
    end

    desc "update", "update the current environment"
    long_desc <<-D
      Update will install the newest versions of the gems listed in the Gemfile. Use
      update when you have changed the Gemfile, or if you want to get the newest
      possible versions of the gems in the bundle.
    D
    method_option "source", :type => :array, :banner => "Update a specific source (and all gems associated with it)"
    method_option "local", :type => :boolean, :banner =>
      "Do not attempt to fetch gems remotely and use the gem cache instead"
    method_option "quiet", :type => :boolean, :banner =>
      "Only output warnings and errors."
    method_option "full-index", :type => :boolean, :banner =>
        "Use the rubygems modern index instead of the API endpoint"
    method_option "jobs", :aliases => "-j", :type => :numeric, :banner =>
      "Specify the number of jobs to run in parallel"
    method_option "group", :aliases => "-g", :type => :array, :banner =>
      "Update a specific group"
    def update(*gems)
      Update.new(options, gems).run
    end

    desc "show [GEM]", "Shows all gems that are part of the bundle, or the path to a given gem"
    long_desc <<-D
      Show lists the names and versions of all gems that are required by your Gemfile.
      Calling show with [GEM] will list the exact location of that gem on your machine.
    D
    method_option "paths", :type => :boolean,
      :banner => "List the paths of all gems that are required by your Gemfile."
    def show(gem_name = nil)
      Show.new(options, gem_name).run
    end
    map %w(list) => "show"

    desc "binstubs [GEM]", "install the binstubs of the listed gem"
    long_desc <<-D
      Generate binstubs for executables in [GEM]. Binstubs are put into bin,
      or the --binstubs directory if one has been set.
    D
    method_option "path", :type => :string, :lazy_default => "bin", :banner =>
      "binstub destination directory (default bin)"
    method_option "force", :type => :boolean, :default => false, :banner =>
      "overwrite existing binstubs if they exist"
    def binstubs(*gems)
      Binstubs.new(options, gems).run
    end

    desc "outdated [GEM]", "list installed gems with newer versions available"
    long_desc <<-D
      Outdated lists the names and versions of gems that have a newer version available
      in the given source. Calling outdated with [GEM [GEM]] will only check for newer
      versions of the given gems. Prerelease gems are ignored by default. If your gems
      are up to date, Bundler will exit with a status of 0. Otherwise, it will exit 1.
    D
    method_option "pre", :type => :boolean, :banner => "Check for newer pre-release gems"
    method_option "source", :type => :array, :banner => "Check against a specific source"
    method_option "local", :type => :boolean, :banner =>
      "Do not attempt to fetch gems remotely and use the gem cache instead"
    method_option "strict", :type => :boolean, :banner =>
      "Only list newer versions allowed by your Gemfile requirements"
    def outdated(*gems)
      Outdated.new(options, gems).run
    end

    desc "cache", "Cache all the gems to vendor/cache", :hide => true
    method_option "no-prune",  :type => :boolean, :banner => "Don't remove stale gems from the cache."
    method_option "all",  :type => :boolean, :banner => "Include all sources (including path and git)."
    def cache
      Cache.new(options).run
    end

    desc "package", "Locks and then caches all of the gems into vendor/cache"
    method_option "no-prune",  :type => :boolean, :banner => "Don't remove stale gems from the cache."
    method_option "all",  :type => :boolean, :banner => "Include all sources (including path and git)."
    method_option "quiet", :type => :boolean, :banner => "Only output warnings and errors."
    method_option "path", :type => :string, :banner =>
      "Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine"
    method_option "gemfile", :type => :string, :banner => "Use the specified gemfile instead of Gemfile"
    long_desc <<-D
      The package command will copy the .gem files for every gem in the bundle into the
      directory ./vendor/cache. If you then check that directory into your source
      control repository, others who check out your source will be able to install the
      bundle without having to download any additional gems.
    D
    def package
      Bundler.ui.level = "warn" if options[:quiet]
      Bundler.settings[:path] = File.expand_path(options[:path]) if options[:path]
      setup_cache_all
      install
      # TODO: move cache contents here now that all bundles are locked
      custom_path = Pathname.new(options[:path]) if options[:path]
      Bundler.load.cache(custom_path)
    end
    map %w(pack) => :package

    desc "exec", "Run the command in context of the bundle"
    method_option :keep_file_descriptors, :type => :boolean, :default => false
    long_desc <<-D
      Exec runs a command, providing it access to the gems in the bundle. While using
      bundle exec you can require and call the bundled gems as if they were installed
      into the system wide Rubygems repository.
    D
    def exec(*args)
      Bundler.definition.validate_ruby!
      Bundler.load.setup_environment

      begin
        if RUBY_VERSION >= "2.0"
          args << { :close_others => !options.keep_file_descriptors? }
        elsif options.keep_file_descriptors?
          Bundler.ui.warn "Ruby version #{RUBY_VERSION} defaults to keeping non-standard file descriptors on Kernel#exec."
        end

        # Run
        Kernel.exec(*args)
      rescue Errno::EACCES
        Bundler.ui.error "bundler: not executable: #{args.first}"
        exit 126
      rescue Errno::ENOENT
        Bundler.ui.error "bundler: command not found: #{args.first}"
        Bundler.ui.warn  "Install missing gem executables with `bundle install`"
        exit 127
      rescue ArgumentError
        Bundler.ui.error "bundler: exec needs a command to run"
        exit 128
      end
    end

    desc "config NAME [VALUE]", "retrieve or set a configuration value"
    long_desc <<-D
      Retrieves or sets a configuration value. If only one parameter is provided, retrieve the value. If two parameters are provided, replace the
      existing value with the newly provided one.

      By default, setting a configuration value sets it for all projects
      on the machine.

      If a global setting is superceded by local configuration, this command
      will show the current value, as well as any superceded values and
      where they were specified.
    D
    def config(*args)
      peek = args.shift

      if peek && peek =~ /^\-\-/
        name, scope = args.shift, $'
      else
        name, scope = peek, "global"
      end

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

      case scope
      when "delete"
        Bundler.settings.set_local(name, nil)
        Bundler.settings.set_global(name, nil)
      when "local", "global"
        if args.empty?
          Bundler.ui.confirm "Settings for `#{name}` in order of priority. The top value will be used"
          with_padding do
            Bundler.settings.pretty_values_for(name).each { |line| Bundler.ui.info line }
          end
          return
        end

        locations = Bundler.settings.locations(name)

        if scope == "global"
          if local = locations[:local]
            Bundler.ui.info "Your application has set #{name} to #{local.inspect}. This will override the " \
              "global value you are currently setting"
          end

          if env = locations[:env]
            Bundler.ui.info "You have a bundler environment variable for #{name} set to #{env.inspect}. " \
              "This will take precedence over the global value you are setting"
          end

          if global = locations[:global]
            Bundler.ui.info "You are replacing the current global value of #{name}, which is currently #{global.inspect}"
          end
        end

        if scope == "local" && local = locations[:local]
          Bundler.ui.info "You are replacing the current local value of #{name}, which is currently #{local.inspect}"
        end

        if name.match(/\Alocal\./)
          pathname = Pathname.new(args.join(" "))
          args = [pathname.expand_path.to_s] if pathname.directory?
        end

        Bundler.settings.send("set_#{scope}", name, args.join(" "))
      else
        Bundler.ui.error "Invalid scope --#{scope} given. Please use --local or --global."
        exit 1
      end
    end

    desc "open GEM", "Opens the source directory of the given bundled gem"
    def open(name)
      editor = [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find{|e| !e.nil? && !e.empty? }
      return Bundler.ui.info("To open a bundled gem, set $EDITOR or $BUNDLER_EDITOR") unless editor
      spec = select_spec(name, :regex_match)
      return unless spec
      full_gem_path = spec.full_gem_path
      Dir.chdir(full_gem_path) do
        command = "#{editor} #{full_gem_path}"
        success = system(command)
        Bundler.ui.info "Could not run '#{command}'" unless success
      end
    end

    CONSOLES = {
      'pry'  => :Pry,
      'ripl' => :Ripl,
      'irb'  => :IRB,
    }

    desc "console [GROUP]", "Opens an IRB session with the bundle pre-loaded"
    def console(group = nil)
      group ? Bundler.require(:default, *(group.split.map! {|g| g.to_sym })) : Bundler.require
      ARGV.clear

      preferred = Bundler.settings[:console] || 'irb'

      # See if console is available
      begin
        require preferred || true
      rescue LoadError
        # Is it in Gemfile?
        Bundler.ui.error "Could not load the #{preferred} console"
        Bundler.ui.info "Falling back on IRB..."

        require 'irb'
        preferred = 'irb'
      end

      constant = CONSOLES[preferred]

      console = begin
                  Object.const_get(constant)
                rescue NameError => e
                  Bundler.ui.error e.inspect
                  Bundler.ui.error "Could not load the #{constant} console"
                  return
                end

      console.start
    end

    desc "version", "Prints the bundler's version information"
    def version
      Bundler.ui.info "Bundler version #{Bundler::VERSION}"
    end
    map %w(-v --version) => :version

    desc "licenses", "Prints the license of all gems in the bundle"
    def licenses
      Bundler.load.specs.sort_by { |s| s.license.to_s }.reverse.each do |s|
        gem_name = s.name
        license  = s.license || s.licenses

        if license.empty?
          Bundler.ui.warn "#{gem_name}: Unknown"
        else
          Bundler.ui.info "#{gem_name}: #{license}"
        end
      end
    end

    desc 'viz', "Generates a visual dependency graph"
    long_desc <<-D
      Viz generates a PNG file of the current Gemfile as a dependency graph.
      Viz requires the ruby-graphviz gem (and its dependencies).
      The associated gems must also be installed via 'bundle install'.
    D
    method_option :file, :type => :string, :default => 'gem_graph', :aliases => '-f', :banner => "The name to use for the generated file. see format option"
    method_option :version, :type => :boolean, :default => false, :aliases => '-v', :banner => "Set to show each gem version."
    method_option :requirements, :type => :boolean, :default => false, :aliases => '-r', :banner => "Set to show the version of each required dependency."
    method_option :format, :type => :string, :default => "png", :aliases => '-F', :banner => "This is output format option. Supported format is png, jpg, svg, dot ..."
    def viz
      require 'graphviz'
      output_file = File.expand_path(options[:file])
      graph = Graph.new(Bundler.load, output_file, options[:version], options[:requirements], options[:format])
      graph.viz
    rescue LoadError => e
      Bundler.ui.error e.inspect
      Bundler.ui.warn "Make sure you have the graphviz ruby gem. You can install it with:"
      Bundler.ui.warn "`gem install ruby-graphviz`"
    rescue StandardError => e
      if e.message =~ /GraphViz not installed or dot not in PATH/
        Bundler.ui.error e.message
        Bundler.ui.warn "Please install GraphViz. On a Mac with homebrew, you can run `brew install graphviz`."
      else
        raise
      end
    end

    desc "gem GEM", "Creates a skeleton for creating a rubygem"
    method_option :bin, :type => :boolean, :default => false, :aliases => '-b', :banner => "Generate a binary for your library."
    method_option :test, :type => :string, :lazy_default => 'rspec', :aliases => '-t', :banner => "Generate a test directory for your library: 'rspec' is the default, but 'minitest' is also supported."
    method_option :edit, :type => :string, :aliases => "-e",
                  :lazy_default => [ENV['BUNDLER_EDITOR'], ENV['VISUAL'], ENV['EDITOR']].find{|e| !e.nil? && !e.empty? },
                  :required => false, :banner => "/path/to/your/editor",
                  :desc => "Open generated gemspec in the specified editor (defaults to $EDITOR or $BUNDLER_EDITOR)"

    def gem(name)
      name = name.chomp("/") # remove trailing slash if present
      namespaced_path = name.tr('-', '/')
      target = File.join(Dir.pwd, name)
      constant_name = name.split('_').map{|p| p[0..0].upcase + p[1..-1] }.join
      constant_name = constant_name.split('-').map{|q| q[0..0].upcase + q[1..-1] }.join('::') if constant_name =~ /-/
      constant_array = constant_name.split('::')
      git_user_name = `git config user.name`.chomp
      git_user_email = `git config user.email`.chomp
      opts = {
        :name            => name,
        :namespaced_path => namespaced_path,
        :constant_name   => constant_name,
        :constant_array  => constant_array,
        :author          => git_user_name.empty? ? "TODO: Write your name" : git_user_name,
        :email           => git_user_email.empty? ? "TODO: Write your email address" : git_user_email,
        :test            => options[:test]
      }
      gemspec_dest = File.join(target, "#{name}.gemspec")
      template(File.join("newgem/Gemfile.tt"),               File.join(target, "Gemfile"),                             opts)
      template(File.join("newgem/Rakefile.tt"),              File.join(target, "Rakefile"),                            opts)
      template(File.join("newgem/LICENSE.txt.tt"),           File.join(target, "LICENSE.txt"),                         opts)
      template(File.join("newgem/README.md.tt"),             File.join(target, "README.md"),                           opts)
      template(File.join("newgem/gitignore.tt"),             File.join(target, ".gitignore"),                          opts)
      template(File.join("newgem/newgem.gemspec.tt"),        gemspec_dest,                                             opts)
      template(File.join("newgem/lib/newgem.rb.tt"),         File.join(target, "lib/#{namespaced_path}.rb"),           opts)
      template(File.join("newgem/lib/newgem/version.rb.tt"), File.join(target, "lib/#{namespaced_path}/version.rb"),   opts)
      if options[:bin]
        template(File.join("newgem/bin/newgem.tt"),          File.join(target, 'bin', name),                           opts)
      end
      case options[:test]
      when 'rspec'
        template(File.join("newgem/rspec.tt"),               File.join(target, ".rspec"),                              opts)
        template(File.join("newgem/spec/spec_helper.rb.tt"), File.join(target, "spec/spec_helper.rb"),                 opts)
        template(File.join("newgem/spec/newgem_spec.rb.tt"), File.join(target, "spec/#{namespaced_path}_spec.rb"),     opts)
      when 'minitest'
        template(File.join("newgem/test/minitest_helper.rb.tt"), File.join(target, "test/minitest_helper.rb"),         opts)
        template(File.join("newgem/test/test_newgem.rb.tt"),     File.join(target, "test/test_#{namespaced_path}.rb"), opts)
      end
      if options[:test]
        template(File.join("newgem/.travis.yml.tt"),         File.join(target, ".travis.yml"),            opts)
      end
      Bundler.ui.info "Initializing git repo in #{target}"
      Dir.chdir(target) { `git init`; `git add .` }

      if options[:edit]
        run("#{options["edit"]} \"#{gemspec_dest}\"")  # Open gemspec in editor
      end
    end

    def self.source_root
      File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
    end

    desc "clean", "Cleans up unused gems in your bundler directory"
    method_option "dry-run", :type => :boolean, :default => false, :banner =>
      "only print out changes, do not actually clean gems"
    method_option "force", :type => :boolean, :default => false, :banner =>
      "forces clean even if --path is not set"
    def clean
      if Bundler.settings[:path] || options[:force]
        Bundler.load.clean(options[:"dry-run"])
      else
        Bundler.ui.error "Can only use bundle clean when --path is set or --force is set"
        exit 1
      end
    end

    desc "platform", "Displays platform compatibility information"
    method_option "ruby", :type => :boolean, :default => false, :banner =>
      "only display ruby related platform information"
    def platform
      platforms, ruby_version = Bundler.ui.silence do
        [ Bundler.definition.platforms.map {|p| "* #{p}" },
          Bundler.definition.ruby_version ]
      end
      output = []

      if options[:ruby]
        if ruby_version
          output << ruby_version
        else
          output << "No ruby version specified"
        end
      else
        output << "Your platform is: #{RUBY_PLATFORM}"
        output << "Your app has gems that work on these platforms:\n#{platforms.join("\n")}"

        if ruby_version
          output << "Your Gemfile specifies a Ruby version requirement:\n* #{ruby_version}"

          begin
            Bundler.definition.validate_ruby!
            output << "Your current platform satisfies the Ruby version requirement."
          rescue RubyVersionMismatch => e
            output << e.message
          end
        else
          output << "Your Gemfile does not specify a Ruby version requirement."
        end
      end

      Bundler.ui.info output.join("\n\n")
    end

    desc "inject GEM VERSION ...", "Add the named gem(s), with version requirements, to the resolved Gemfile"
    def inject(name, version, *gems)
      # The required arguments allow Thor to give useful feedback when the arguments
      # are incorrect. This adds those first two arguments onto the list as a whole.
      gems.unshift(version).unshift(name)

      # Build an array of Dependency objects out of the arguments
      deps = []
      gems.each_slice(2) do |gem_name, gem_version|
        deps << Bundler::Dependency.new(gem_name, gem_version)
      end

      added = Injector.inject(deps)

      if added.any?
        Bundler.ui.confirm "Added to Gemfile:"
        Bundler.ui.confirm added.map{ |g| "  #{g}" }.join("\n")
      else
        Bundler.ui.confirm "All injected gems were already present in the Gemfile"
      end
    end

    desc "env", "Print information about the environment Bundler is running under"
    def env
      Env.new.write($stdout)
    end

  private

    def setup_cache_all
      Bundler.settings[:cache_all] = options[:all] if options.key?("all")

      if Bundler.definition.sources.any? { |s| !s.is_a?(Source::Rubygems) } && !Bundler.settings[:cache_all]
        Bundler.ui.warn "Your Gemfile contains path and git dependencies. If you want "    \
          "to package them as well, please pass the --all flag. This will be the default " \
          "on Bundler 2.0."
      end
    end

    def select_spec(name, regex_match = nil)
      specs = []
      regexp = Regexp.new(name) if regex_match

      Bundler.definition.specs.each do |spec|
        return spec if spec.name == name
        specs << spec if regexp && spec.name =~ regexp
      end

      case specs.count
      when 0
        raise GemNotFound, not_found_message(name, Bundler.definition.dependencies)
      when 1
        specs.first
      else
        specs.each_with_index do |spec, index|
          Bundler.ui.info "#{index.succ} : #{spec.name}", true
        end
        Bundler.ui.info '0 : - exit -', true

        input = Bundler.ui.ask('> ')
        (num = input.to_i) > 0 ? specs[num - 1] : nil
      end
    end

    def not_found_message(missing_gem_name, alternatives)
      message = "Could not find gem '#{missing_gem_name}'."

      # This is called as the result of a GemNotFound, let's see if
      # there's any similarly named ones we can propose instead
      alternate_names = alternatives.map { |a| a.respond_to?(:name) ? a.name : a }
      suggestions = SimilarityDetector.new(alternate_names).similar_word_list(missing_gem_name)
      message += "\nDid you mean #{suggestions}?" if suggestions
      message
    end

    def without_groups_message
      groups = Bundler.settings.without
      group_list = [groups[0...-1].join(", "), groups[-1..-1]].
        reject{|s| s.to_s.empty? }.join(" and ")
      group_str = (groups.size == 1) ? "group" : "groups"
      "Gems in the #{group_str} #{group_list} were not installed."
    end

  end
end

require 'bundler/cli/init'
require 'bundler/cli/check'
require 'bundler/cli/install'
require 'bundler/cli/update'
require 'bundler/cli/show'
require 'bundler/cli/binstubs'
require 'bundler/cli/outdated'
require 'bundler/cli/cache'
