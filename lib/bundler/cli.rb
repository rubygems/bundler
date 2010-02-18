$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'rubygems/config_file'

# Work around a RubyGems bug
Gem.configuration

module Bundler
  class CLI < Thor
    ARGV = ::ARGV.dup

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
        puts "The following dependencies are missing"
        missing.each do |d|
          puts "  * #{d}"
        end
        exit 1
      else
        env.specs
        puts "The Gemfile's dependencies are satisfied"
      end
    end

    desc "install", "Install the current environment to the system"
    method_option "without", :type => :array,   :banner => "Exclude gems that are part of the specified named group."
    method_option "relock",  :type => :boolean, :banner => "Unlock, install the gems, and relock."
    method_option "disable-shared-gems", :type => :boolean, :banner => "Do not use any shared gems, such as the system gem repository."
    def install(path = nil)
      opts = options.dup
      opts[:without] ||= []
      opts[:without].map! { |g| g.to_sym }

      Bundler.settings[:path] = path if path
      Bundler.settings[:disable_shared_gems] = '1' if options["disable-shared-gems"]

      remove_lockfiles if options[:relock]

      Installer.install(Bundler.root, Bundler.definition, opts)
      # Ensures that .bundle/environment.rb exists
      # TODO: Figure out a less hackish way to do this
      Bundler.load

      lock if options[:relock]
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

    desc "show", "Shows all gems that are part of the bundle."
    def show
      environment = Bundler.load
      Bundler.ui.info "Gems included by the bundle:"
      environment.specs.sort_by { |s| s.name }.each do |s|
        Bundler.ui.info "  * #{s.name} (#{s.version})"
      end
    end

    desc "pack", "Packs all the gems to vendor/cache"
    def pack
      environment = Bundler.load
      environment.pack
    end

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
      rubyopt = [ENV["RUBYOPT"]].compact
      rubyopt.unshift "-rbundler/setup"
      rubyopt.unshift "-I#{File.expand_path('../..', __FILE__)}"
      ENV["RUBYOPT"] = rubyopt.join(' ')

      # Run
      Kernel.exec *ARGV
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
  end
end
