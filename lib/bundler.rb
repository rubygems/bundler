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
  autoload :Graph,               'bundler/graph'
  autoload :Index,               'bundler/index'
  autoload :Installer,           'bundler/installer'
  autoload :LazySpecification,   'bundler/lazy_specification'
  autoload :LockfileParser,      'bundler/lockfile_parser'
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
  class GemfileChanged   < GemfileError; status_code(4)  ; end
  class PathError        < BundlerError; status_code(13) ; end
  class GitError         < BundlerError; status_code(11) ; end
  class GemspecError     < BundlerError; status_code(14) ; end
  class DeprecatedMethod < BundlerError; status_code(12) ; end
  class DeprecatedOption < BundlerError; status_code(12) ; end
  class GemspecError     < BundlerError; status_code(14) ; end
  class InvalidOption    < BundlerError; status_code(15) ; end

  # Internal errors, should be rescued
  class InvalidSpecSet < StandardError; end

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
        path = settings[:path] || Gem.dir
        Pathname.new(path).expand_path(root)
      end
    end

    def bin_path
      @bin_path ||= begin
        path = settings[:bin] || "#{Gem.user_home}/.bundler/bin"
        FileUtils.mkdir_p(path)
        Pathname.new(path).expand_path
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
      @load ||= Runtime.new(root, definition)
    end

    def environment
      Bundler::Environment.new(root, definition)
    end

    def definition
      @definition ||= begin
        configure
        lockfile = root.join("Gemfile.lock")
        Definition.build(default_gemfile, lockfile)
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
      default_gemfile.dirname.expand_path
    end

    def app_cache
      root.join("vendor/cache")
    end

    def tmp
      "#{Gem.user_home}/.bundler/tmp"
    end

    def settings
      @settings ||= Settings.new(root)
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

    def requires_sudo?
      case
      when File.writable?(bundle_path) ||
           `which sudo 2>NUL`.empty? ||
           File.owned?(bundle_path)
        false
      else
        true
      end
    rescue Errno::ENOENT
      false
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
  end
end
