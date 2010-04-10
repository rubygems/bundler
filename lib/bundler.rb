require 'fileutils'
require 'pathname'
require 'yaml'
require 'bundler/rubygems_ext'
require 'bundler/version'

module Bundler
  ORIGINAL_ENV = ENV.to_hash

  autoload :Definition,          'bundler/definition'
  autoload :Dependency,          'bundler/dependency'
  autoload :Dsl,                 'bundler/dsl'
  autoload :Environment,         'bundler/environment'
  autoload :Index,               'bundler/index'
  autoload :Installer,           'bundler/installer'
  autoload :RemoteSpecification, 'bundler/remote_specification'
  autoload :Resolver,            'bundler/resolver'
  autoload :Runtime,             'bundler/runtime'
  autoload :Settings,            'bundler/settings'
  autoload :SharedHelpers,       'bundler/shared_helpers'
  autoload :SpecSet,             'bundler/spec_set'
  autoload :Source,              'bundler/source'
  autoload :Specification,       'bundler/shared_helpers'
  autoload :UI,                  'bundler/ui'

  class BundlerError < StandardError
    def self.status_code(code = nil)
      return @code unless code
      @code = code
    end

    def status_code
      self.class.status_code
    end
  end

  class GemfileNotFound  < BundlerError; status_code(10) ; end
  class GemNotFound      < BundlerError; status_code(7)  ; end
  class VersionConflict  < BundlerError; status_code(6)  ; end
  class GemfileError     < BundlerError; status_code(4)  ; end
  class PathError        < BundlerError; status_code(13) ; end
  class GitError         < BundlerError; status_code(11) ; end
  class DeprecatedMethod < BundlerError; status_code(12) ; end
  class DeprecatedOption < BundlerError; status_code(12) ; end
  class InvalidOption    < BundlerError; status_code(15) ; end

  class << self
    attr_writer :ui, :bundle_path

    def configure
      @configured ||= begin
        configure_gem_home_and_path
        true
      end
    end

    def ui
      @ui ||= UI.new
    end

    def bundle_path
      @bundle_path ||= begin
        path = settings[:path] || "#{Gem.user_home}/.bundle/#{Gem.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}"
        Pathname.new(path).expand_path(root)
      end
    end

    def setup(*groups)
      return @setup if @setup

      if groups.empty?
        # Load all groups, but only once
        @setup = load.setup
      else
        # Figure out which groups haven't been loaded yet
        unloaded = groups - (@completed_groups || [])
        # Record groups that are now loaded
        @completed_groups = groups | (@completed_groups || [])
        # Load any groups that are not yet loaded
        unloaded.any? ? load.setup(*unloaded) : load
      end
    end

    def require(*groups)
      setup(*groups).require(*groups)
    end

    def load
      @load ||= begin
        if current_env_file?
          @gem_loaded = true
          Kernel.require env_file
          Bundler
        else
          runtime
        end
      end
    end

    def runtime
      @runtime ||= Runtime.new(root, definition)
    end

    def definition
      configure
      lockfile = root.join("Gemfile.lock")
      if lockfile.exist?
        Definition.from_lock(lockfile)
      else
        Definition.from_gemfile(default_gemfile)
      end
    end

    def home
      bundle_path.join("bundler")
    end

    def install_path
      home.join("gems")
    end

    def specs_path
      bundle_path.join("specifications")
    end

    def cache
      bundle_path.join("cache/bundler")
    end

    def root
      default_gemfile.dirname
    end

    def settings
      @settings ||= Settings.new(root)
    end

    def env_file
      SharedHelpers.env_file
    end

    def with_clean_env
      bundled_env = ENV.to_hash
      ENV.replace(ORIGINAL_ENV)
      yield
    ensure
      ENV.replace(bundled_env.to_hash)
    end

    def default_gemfile
      SharedHelpers.default_gemfile
    end

  private

    def configure_gem_home_and_path
      if settings[:disable_shared_gems]
        ENV['GEM_PATH'] = ''
        ENV['GEM_HOME'] = File.expand_path(bundle_path, root)
      else
        paths = [Gem.dir, Gem.path].flatten.compact.uniq.reject{|p| p.empty? }
        ENV["GEM_PATH"] = paths.join(File::PATH_SEPARATOR)
        ENV["GEM_HOME"] = bundle_path.to_s
      end

      Gem.clear_paths
    end

    def current_env_file?
      env_file.exist? && (env_file.read(100) =~ /Bundler #{Bundler::VERSION}/)
    end
  end
end
