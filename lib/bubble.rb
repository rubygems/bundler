require 'pathname'
require 'yaml'
require 'bubble/rubygems'

module Bubble
  VERSION = "0.9.0.pre"

  autoload :Definition,          'bubble/definition'
  autoload :Dependency,          'bubble/dependency'
  autoload :Dsl,                 'bubble/dsl'
  autoload :Environment,         'bubble/environment'
  autoload :Index,               'bubble/index'
  autoload :Installer,           'bubble/installer'
  autoload :RemoteSpecification, 'bubble/remote_specification'
  autoload :Resolver,            'bubble/resolver'
  autoload :Source,              'bubble/source'
  autoload :Specification,       'bubble/specification'

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
    lockfile = Pathname.new(gemfile || default_gemfile).dirname.join('omg.yml')
    if lockfile.exist?
      Definition.from_lock(lockfile)
    else
      Definition.from_gemfile(gemfile)
    end
  end

  def self.home
    Pathname.new(Gem.dir).join("bubble")
  end

  def self.install_path
    home.join("gems")
  end

  def self.cache
    home.join("cache")
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