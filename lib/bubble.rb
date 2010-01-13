require 'pathname'
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

  class GemfileNotFound < StandardError; end
  class GemNotFound     < StandardError; end
  class VersionConflict < StandardError; end

  def self.setup(gemfile = nil)
    load(gemfile).setup
  end

  def self.load(gemfile = nil)
    Environment.new(definition(gemfile))
  end

  def self.definition(gemfile = nil)
    Definition.from_gemfile(gemfile)
  end

  def self.home
    Pathname.new(Gem.user_home).join(".bbl")
  end

  def self.cache
    home.join("cache")
  end


end