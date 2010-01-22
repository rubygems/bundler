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

  def self.setup(gemfile = nil)
    load(gemfile).setup
  end

  def self.load(gemfile = nil)
    Environment.new definition(gemfile)
  end

  def self.definition(gemfile = nil)
    lockfile = Pathname.new(gemfile || Definition.default_gemfile).dirname.join('omg.yml')
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
end