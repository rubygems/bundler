$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bundler
  class CLI < Thor
    check_unknown_options! unless ARGV.include?("exec")

    desc "init", "Generates a Gemfile into the current working directory"
    def init
      if File.exist?("Gemfile")
        puts "Gemfile already exists at #{Dir.pwd}/Gemfile"
      else
        puts "Writing new Gemfile to #{Dir.pwd}/Gemfile"
        FileUtils.cp(File.expand_path('../templates/Gemfile', __FILE__), 'Gemfile')
      end
    end

    def initialize(*)
      super
      Bundler.ui = UI::Shell.new(shell)
      Gem::DefaultUserInteraction.ui = UI::RGProxy.new(Bundler.ui)
    end

    desc "check", "Checks if the dependencies listed in Gemfile are satisfied by currently installed gems"
    def check
      env = Bundler.load
      # Check top level dependencies
      missing = env.dependencies.select { |d| env.index.search(d).empty? }
      if missing.any?
        Bundler.ui.error "The following dependencies are missing"
        missing.each do |d|
          Bundler.ui.error "  * #{d}"
        end
        Bundler.ui.error "Try running `bundle install`"
        exit 1
      else
        not_installed = env.requested_specs.select { |spec| !spec.loaded_from }

        if not_installed.any?
          not_installed.each { |s| Bundler.ui.error "#{s.name} (#{s.version}) is cached, but not installed" }
          Bundler.ui.error "Try running `bundle install`"
          exit 1
        else
          Bundler.ui.info "The Gemfile's dependencies are satisfied"
        end
      end
    end

    desc "install", "Install the current environment to the system"
    method_option "without", :type => :array,   :banner => "Exclude gems that are part of the specified named group."
    method_option "relock",  :type => :boolean, :banner => "Unlock, install the gems, and relock."
    method_option "disable-shared-gems", :type => :boolean, :banner => "Do not use any shared gems, such as the system gem repository."
    method_option "gemfile", :type => :string, :banner => "Use the specified gemfile instead of Gemfile"
    def install(path = nil)
      opts = options.dup
      opts[:without] ||= []
      opts[:without].map! { |g| g.to_sym }

      # Can't use Bundler.settings for this because settings needs gemfile.dirname
      ENV['BUNDLE_GEMFILE'] = opts[:gemfile] if opts[:gemfile]
      Bundler.settings[:path] = path if path
      Bundler.settings[:disable_shared_gems] = '1' if options["disable-shared-gems"]
      Bundler.settings.without = opts[:without]

      remove_lockfiles if options[:relock]

      Installer.install(Bundler.root, Bundler.definition, opts)

      lock if options[:relock]
    rescue GemNotFound => e
      if Bundler.definition.sources.empty?
        Bundler.ui.warn "Your Gemfile doesn't have any sources. You can add one with a line like 'source :gemcutter'"
      end
      raise e
    end

    desc "lock", "Locks the bundle to the current set of dependencies, including all child dependencies."
    def lock
      if locked?
        Bundler.ui.info("The bundle is already locked, relocking.")
        remove_lockfiles
      end

      environment = Bundler.load
      environment.lock
    rescue GemNotFound, VersionConflict => e
      Bundler.ui.error(e.message)
      Bundler.ui.info "Run `bundle install` to install missing gems"
      exit 128
    end

    desc "unlock", "Unlock the bundle. This allows gem versions to be changed"
    def unlock
      if locked?
        remove_lockfiles
        Bundler.ui.info("The bundle is now unlocked. The dependencies may be changed.")
      else
        Bundler.ui.info("The bundle is not currently locked.")
      end
    end

    desc "show GEM", "Shows all gems that are part of the bundle, or the path to a given gem"
    def show(gem_name = nil)
      if gem_name
        Bundler.ui.info locate_gem(gem_name)
      else
        environment = Bundler.load
        Bundler.ui.info "Gems included by the bundle:"
        environment.specs.sort_by { |s| s.name }.each do |s|
          Bundler.ui.info "  * #{s.name} (#{s.version})"
        end
      end
    end

    desc "cache", "Cache all the gems to vendor/cache"
    def cache
      environment = Bundler.load
      environment.cache
    rescue GemNotFound => e
      Bundler.ui.error(e.message)
      Bundler.ui.info "Run `bundle install` to install missing gems."
      exit 128
    end

    desc "package", "Locks and then caches all of the gems into vendor/cache"
    def package
      lock
      cache
    end
    map %w(pack) => :package

    desc "exec", "Run the command in context of the bundle"
    def exec(*)
      ARGV.delete('exec')

      # Set PATH
      paths = (ENV['PATH'] || "").split(File::PATH_SEPARATOR)
      paths.unshift "#{Bundler.bundle_path}/bin"
      ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

      # Set BUNDLE_GEMFILE
      ENV['BUNDLE_GEMFILE'] = Bundler::SharedHelpers.default_gemfile.to_s

      # Set RUBYOPT
      locked_env = Bundler.root.join(".bundle/environment.rb")
      rubyopt = [ENV["RUBYOPT"]].compact
      if locked_env.exist?
        rubyopt.unshift "-r#{locked_env.to_s}"
      else
        rubyopt.unshift "-rbundler/setup"
        rubyopt.unshift "-I#{File.expand_path('../..', __FILE__)}"
      end
      ENV["RUBYOPT"] = rubyopt.join(' ')

      # Run
      Kernel.exec *ARGV
    end

    desc "open GEM", "Opens the source directory of the given bundled gem"
    def open(name)
      editor = ENV['EDITOR']
      return Bundler.ui.info("To open a bundled gem, set $EDITOR") if editor.nil? || editor.empty?
      command = "#{editor} #{locate_gem(name)}"
      Bundler.ui.info "Could not run '#{command}'" unless system(command)
    end

    desc "version", "Prints the bundler's version information"
    def version
      Bundler.ui.info "Bundler version #{Bundler::VERSION}"
    end
    map %w(-v --version) => :version

  private

    def locked?
      File.exist?("#{Bundler.root}/Gemfile.lock") || File.exist?("#{Bundler.root}/.bundle/environment.rb")
    end

    def remove_lockfiles
      FileUtils.rm_f "#{Bundler.root}/Gemfile.lock"
      FileUtils.rm_f "#{Bundler.root}/.bundle/environment.rb"
    end

    def locate_gem(name)
      spec = Bundler.load.specs.find{|s| s.name == name }
      raise GemNotFound, "Could not find gem '#{name}' in the current bundle." unless spec
      spec.full_gem_path
    end

    def self.printable_tasks
      tasks = super.dup
      nodoc = /^bundle (cache)/
      tasks.reject!{|t| t.first =~ nodoc }
      tasks
    end
  end
end
