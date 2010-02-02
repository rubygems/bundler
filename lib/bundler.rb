require 'fileutils'
require 'pathname'
require 'yaml'
require 'bundler/rubygems'

module Bundler
  VERSION = "0.9.0.pre4"

  autoload :Definition,          'bundler/definition'
  autoload :Dependency,          'bundler/dependency'
  autoload :Dsl,                 'bundler/dsl'
  autoload :Environment,         'bundler/environment'
  autoload :Index,               'bundler/index'
  autoload :Installer,           'bundler/installer'
  autoload :RemoteSpecification, 'bundler/remote_specification'
  autoload :Resolver,            'bundler/resolver'
  autoload :Source,              'bundler/source'
  autoload :Specification,       'bundler/specification'
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

  class GemfileNotFound < BundlerError; status_code(10) ; end
  class GemNotFound     < BundlerError; status_code(7)  ; end
  class VersionConflict < BundlerError; status_code(6)  ; end
  class GemfileError    < BundlerError; status_code(4)  ; end

  class << self
    attr_accessor :ui, :bundle_path

    def configure
      @configured ||= begin
        point_gem_home(env[:bundle_path])
        true
      end
    end

    def ui
      @ui ||= UI.new
    end

    def bundle_path
      @bundle_path ||= Pathname.new(env[:bundle_path] || Gem.dir)
    end

    def setup(*groups)
      gemfile = default_gemfile
      load(gemfile).setup(*groups)
    end

    def load(gemfile = default_gemfile)
      root = Pathname.new(gemfile).dirname
      Environment.new root, definition(gemfile)
    end

    def definition(gemfile = default_gemfile)
      configure
      root = Pathname.new(gemfile).dirname
      lockfile = root.join("vendor/lock.yml")
      if lockfile.exist?
        Definition.from_lock(lockfile)
      else
        Definition.from_gemfile(gemfile)
      end
    end

    def home
      Pathname.new(bundle_path).join("bundler")
    end

    def install_path
      home.join("gems")
    end

    def cache
      home.join("cache")
    end

    def root
      default_gemfile.dirname
    end

  private

    def default_gemfile
      current = Pathname.new(Dir.pwd)

      until current.root?
        filename = current.join("Gemfile")
        return filename if filename.exist?
        current = current.parent
      end

      raise GemfileNotFound, "The default Gemfile was not found"
    end

    def env
      @env ||= begin
        env    = {}
        file   = "#{root}/.bundleconfig"
        config = File.exist?(file) ? YAML.load_file(file) : {}
        %w(BUNDLE_PATH).each do |key|
          env[key.downcase.to_sym] = config[key] || ENV[key]
        end
        env
      end
    end

    def point_gem_home(path)
      return unless path
      ENV['GEM_HOME'] = File.expand_path(path, root)
      ENV['GEM_PATH'] = ''
      Gem.clear_paths
    end
  end
end