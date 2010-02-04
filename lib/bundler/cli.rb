$:.unshift File.expand_path('../vendor', __FILE__)
require 'thor'
require 'bundler'
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
      else
        env.specs
        puts "The Gemfile's dependencies are satisfied"
      end
    end

    desc "install", "Install the current environment to the system"
    method_option :without, :type => :array, :banner => "Exclude gems thar are part of the specified named group"
    def install(path = nil)
      opts = options.dup
      opts[:without] ||= []
      opts[:without].map! { |g| g.to_sym }

      Bundler.settings[:path] = path if path

      Installer.install(Bundler.root, Bundler.definition, opts)
    end

    desc "lock", "Locks the bundle to the current set of dependencies, including all child dependencies."
    def lock
      if File.exist?("#{Bundler.root}/Gemfile.lock")
        Bundler.ui.info("The bundle is already locked, relocking.")
        `rm #{Bundler.root}/Gemfile.lock`
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
      environment = Bundler.load
      environment.unlock
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
      ENV["RUBYOPT"] = %W(
        -I#{File.expand_path('../..', __FILE__)}
        -rbundler/setup
        #{ENV["RUBYOPT"]}
      ).compact.join(' ')
      Kernel.exec *ARGV
    end

  end
end
