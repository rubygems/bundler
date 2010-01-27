require 'fileutils'
require 'pathname'
require 'yaml'
require 'bundler/rubygems'

module Bundler
  VERSION = "0.9.0.pre"

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

  class GemfileNotFound < StandardError; end
  class GemNotFound     < StandardError; end
  class VersionConflict < StandardError; end
  class GemfileError    < StandardError; end

  def self.ui
    @ui ||= UI.new
  end

  def self.ui=(ui)
    @ui = ui
  end

  def self.setup(gemfile = default_gemfile)
    load(gemfile).setup
  end

  def self.load(gemfile = default_gemfile)
    root = Pathname.new(gemfile).dirname
    Environment.new root, definition(gemfile)
  end

  def self.definition(gemfile = default_gemfile)
    root = Pathname.new(gemfile).dirname
    lockfile = root.join("vendor/lock.yml")
    if lockfile.exist?
      Definition.from_lock(lockfile)
    else
      Definition.from_gemfile(gemfile)
    end
  end

  def self.home
    Pathname.new(Gem.dir).join("gemfile")
  end

  def self.install_path
    home.join("gems")
  end

  def self.cache
    home.join("cache")
  end

  def self.root
    default_gemfile.dirname
  end

private

  def self.default_gemfile
    current = Pathname.new(Dir.pwd)

    until current.root?
      filename = current.join("Gemfile")
      return filename if filename.exist?
      current = current.parent
    end

    raise GemfileNotFound, "The default Gemfile was not found"
  end

end