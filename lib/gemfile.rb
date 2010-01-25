require 'fileutils'
require 'pathname'
require 'yaml'
require 'gemfile/rubygems'

module Gemfile
  VERSION = "0.9.0.pre"

  autoload :Definition,          'gemfile/definition'
  autoload :Dependency,          'gemfile/dependency'
  autoload :Dsl,                 'gemfile/dsl'
  autoload :Environment,         'gemfile/environment'
  autoload :Index,               'gemfile/index'
  autoload :Installer,           'gemfile/installer'
  autoload :RemoteSpecification, 'gemfile/remote_specification'
  autoload :Resolver,            'gemfile/resolver'
  autoload :Source,              'gemfile/source'
  autoload :Specification,       'gemfile/specification'

  class GemfileNotFound < StandardError; end
  class GemNotFound     < StandardError; end
  class VersionConflict < StandardError; end
  class GemfileError    < StandardError; end

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