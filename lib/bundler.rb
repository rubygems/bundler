require 'rbconfig'
require 'fileutils'
require 'pathname'
require 'bundler/gem_path_manipulation'
require 'bundler/psyched_yaml'
require 'bundler/rubygems_ext'
require 'bundler/rubygems_integration'
require 'bundler/version'

module Bundler
  preserve_gem_path
  ORIGINAL_ENV = ENV.to_hash

  autoload :Definition,            'bundler/definition'
  autoload :Dependency,            'bundler/dependency'
  autoload :DepProxy,              'bundler/dep_proxy'
  autoload :Dsl,                   'bundler/dsl'
  autoload :EndpointSpecification, 'bundler/endpoint_specification'
  autoload :Environment,           'bundler/environment'
  autoload :Fetcher,               'bundler/fetcher'
  autoload :GemHelper,             'bundler/gem_helper'
  autoload :GemHelpers,            'bundler/gem_helpers'
  autoload :GemInstaller,          'bundler/gem_installer'
  autoload :Graph,                 'bundler/graph'
  autoload :Index,                 'bundler/index'
  autoload :Installer,             'bundler/installer'
  autoload :LazySpecification,     'bundler/lazy_specification'
  autoload :LockfileParser,        'bundler/lockfile_parser'
  autoload :MatchPlatform,         'bundler/match_platform'
  autoload :RemoteSpecification,   'bundler/remote_specification'
  autoload :Resolver,              'bundler/resolver'
  autoload :RubyVersion,           'bundler/ruby_version'
  autoload :Runtime,               'bundler/runtime'
  autoload :Settings,              'bundler/settings'
  autoload :SharedHelpers,         'bundler/shared_helpers'
  autoload :SpecSet,               'bundler/spec_set'
  autoload :Source,                'bundler/source'
  autoload :Specification,         'bundler/shared_helpers'
  autoload :SystemRubyVersion,     'bundler/ruby_version'
  autoload :UI,                    'bundler/ui'

  class BundlerError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class GemfileNotFound     < BundlerError; status_code(10) ; end
  class GemNotFound         < BundlerError; status_code(7)  ; end
  class GemfileError        < BundlerError; status_code(4)  ; end
  class InstallError        < BundlerError; status_code(5)  ; end
  class InstallHookError    < BundlerError; status_code(6)  ; end
  class PathError           < BundlerError; status_code(13) ; end
  class GitError            < BundlerError; status_code(11) ; end
  class DeprecatedError     < BundlerError; status_code(12) ; end
  class GemspecError        < BundlerError; status_code(14) ; end
  class DslError            < BundlerError; status_code(15) ; end
  class ProductionError     < BundlerError; status_code(16) ; end
  class InvalidOption       < DslError                      ; end
  class HTTPError           < BundlerError; status_code(17) ; end
  class RubyVersionMismatch < BundlerError; status_code(18) ; end


  WINDOWS = RbConfig::CONFIG["host_os"] =~ %r!(msdos|mswin|djgpp|mingw)!
  FREEBSD = RbConfig::CONFIG["host_os"] =~ /bsd/
  NULL    = WINDOWS ? "NUL" : "/dev/null"

  # Internal errors, should be rescued
  class VersionConflict  < BundlerError
    attr_reader :conflicts

    def initialize(conflicts, msg = nil)
      super(msg)
      @conflicts = conflicts
    end

    status_code(6)
  end

  class InvalidSpecSet < StandardError; end

  class << self
    attr_writer :ui, :bundle_path

    def configure
      @configured ||= configure_gem_home_and_path
    end

    def ui
      @ui ||= UI.new
    end

    # Returns absolute path of where gems are installed on the filesystem.
    def bundle_path
      @bundle_path ||= Pathname.new(settings.path).expand_path(root)
    end

    # Returns absolute location of where binstubs are installed to.
    def bin_path
      @bin_path ||= begin
        path = settings[:bin] || "bin"
        path = Pathname.new(path).expand_path(root)
        FileUtils.mkdir_p(path)
        Pathname.new(path).expand_path
      end
    end

    def setup(*groups)
      # Just return if all groups are already loaded
      return @setup if defined?(@setup)

      definition.validate_ruby!

      if groups.empty?
        # Load all groups, but only once
        @setup = load.setup
      else
        @completed_groups ||= []
        # Figure out which groups haven't been loaded yet
        unloaded = groups - @completed_groups
        # Record groups that are now loaded
        @completed_groups = groups
        unloaded.any? ? load.setup(*groups) : load
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

    def definition(unlock = nil)
      @definition = nil if unlock
      @definition ||= begin
        configure
        upgrade_lockfile
        Definition.build(default_gemfile, default_lockfile, unlock)
      end
    end

    def ruby_scope
      "#{Bundler.rubygems.ruby_engine}/#{Gem::ConfigMap[:ruby_version]}"
    end

    def user_bundle_path
      Pathname.new(Bundler.rubygems.user_home).join(".bundler")
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

    def app_config_path
      ENV['BUNDLE_APP_CONFIG'] ?
        Pathname.new(ENV['BUNDLE_APP_CONFIG']).expand_path(root) :
        root.join('.bundle')
    end

    def app_cache
      root.join("vendor/cache")
    end

    def tmp
      user_bundle_path.join("tmp", Process.pid.to_s)
    end

    def settings
      @settings ||= Settings.new(app_config_path)
    end

    def with_original_env
      bundled_env = ENV.to_hash
      ENV.replace(ORIGINAL_ENV)
      yield
    ensure
      ENV.replace(bundled_env.to_hash)
    end

    def with_clean_env
      with_original_env do
        ENV.delete_if { |k,_| k[0,7] == 'BUNDLE_' }
        if ENV.has_key? 'RUBYOPT'
          ENV['RUBYOPT'] = ENV['RUBYOPT'].sub '-rbundler/setup', ''
          ENV['RUBYOPT'] = ENV['RUBYOPT'].sub "-I#{File.expand_path('..', __FILE__)}", ''
        end
        yield
      end
    end

    def clean_system(*args)
      with_clean_env { Kernel.system(*args) }
    end

    def clean_exec(*args)
      with_clean_env { Kernel.exec(*args) }
    end

    def default_gemfile
      SharedHelpers.default_gemfile
    end

    def default_lockfile
      SharedHelpers.default_lockfile
    end

    def system_bindir
      # Gem.bindir doesn't always return the location that Rubygems will install
      # system binaries. If you put '-n foo' in your .gemrc, Rubygems will
      # install binstubs there instead. Unfortunately, Rubygems doesn't expose
      # that directory at all, so rather than parse .gemrc ourselves, we allow
      # the directory to be set as well, via `bundle config bindir foo`.
      Bundler.settings[:system_bindir] || Bundler.rubygems.gem_bindir
    end

    def requires_sudo?
      return @requires_sudo if defined?(@checked_for_sudo)

      path = bundle_path
      path = path.parent until path.exist?
      sudo_present = which "sudo"
      bin_dir = Pathname.new(Bundler.system_bindir)
      bin_dir = bin_dir.parent until bin_dir.exist?

      @checked_for_sudo = true
      sudo_gems = !File.writable?(path) || !File.writable?(bin_dir)
      @requires_sudo = settings.allow_sudo? && sudo_gems && sudo_present
    end

    def mkdir_p(path)
      if requires_sudo?
        sudo "mkdir -p '#{path}'" unless File.exist?(path)
      else
        FileUtils.mkdir_p(path)
      end
    end

    def which(executable)
      if File.executable?(executable)
        executable
      elsif ENV['PATH']
        path = ENV['PATH'].split(File::PATH_SEPARATOR).find do |p|
          File.executable?(File.join(p, executable))
        end
        path && File.expand_path(executable, path)
      end
    end

    def sudo(str)
      `sudo -p 'Enter your password to install the bundled RubyGems to your system: ' #{str}`
    end

    def read_file(file)
      File.open(file, "rb") { |f| f.read }
    end

    def load_gemspec(file)
      @gemspec_cache ||= {}
      key = File.expand_path(file)
      spec = ( @gemspec_cache[key] ||= load_gemspec_uncached(file) )
      # Protect against caching side-effected gemspecs by returning a
      # new instance each time.
      spec.dup if spec
    end

    def load_gemspec_uncached(file)
      path = Pathname.new(file)
      # Eval the gemspec from its parent directory
      Dir.chdir(path.dirname.to_s) do
        contents = File.read(path.basename.to_s)

        if contents =~ /\A---/ # try YAML
          begin
            Gem::Specification.from_yaml(contents)
          rescue ArgumentError, YamlSyntaxError, Gem::EndOfYAMLException, Gem::Exception
            eval_gemspec(path, contents)
          end
        else
          eval_gemspec(path, contents)
        end
      end
    end

    def clear_gemspec_cache
      @gemspec_cache = {}
    end

  private

    def eval_gemspec(path, contents)
      eval(contents, TOPLEVEL_BINDING, path.expand_path.to_s)
    rescue LoadError, SyntaxError => e
      original_line = e.backtrace.find { |line| line.include?(path.to_s) }
      msg  = "There was a #{e.class} while evaluating #{path.basename}: \n#{e.message}"
      msg << " from\n  #{original_line}" if original_line
      msg << "\n"

      if e.is_a?(LoadError) && RUBY_VERSION >= "1.9"
        msg << "\nDoes it try to require a relative path? That's been removed in Ruby 1.9."
      end

      raise GemspecError, msg
    end

    def configure_gem_home_and_path
      blank_home = ENV['GEM_HOME'].nil? || ENV['GEM_HOME'].empty?

      if settings[:disable_shared_gems]
        ENV['GEM_PATH'] = ''
        configure_gem_home
      elsif blank_home || Bundler.rubygems.gem_dir != bundle_path.to_s
        possibles = [Bundler.rubygems.gem_dir, Bundler.rubygems.gem_path]
        paths = possibles.flatten.compact.uniq.reject { |p| p.empty? }
        ENV["GEM_PATH"] = paths.join(File::PATH_SEPARATOR)
        configure_gem_home
      end

      Bundler.rubygems.refresh
      bundle_path
    end

    def configure_gem_home
      # TODO: This mkdir_p is only needed for JRuby <= 1.5 and should go away (GH #602)
      FileUtils.mkdir_p bundle_path.to_s rescue nil

      ENV['GEM_HOME'] = File.expand_path(bundle_path, root)
      Bundler.rubygems.clear_paths
    end

    def upgrade_lockfile
      lockfile = default_lockfile
      if lockfile.exist? && lockfile.read(3) == "---"
        Bundler.ui.warn "Detected Gemfile.lock generated by 0.9, deleting..."
        lockfile.rmtree
      end
    end

  end
end
