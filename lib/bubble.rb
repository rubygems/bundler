module Bubble
  VERSION = "0.9.0.pre"

  autoload :Definition,  'bubble/definition'
  autoload :Dependency,  'bubble/dependency'
  autoload :Dsl,         'bubble/dsl'
  autoload :Environment, 'bubble/environment'

  class GemfileNotFound < StandardError; end
  class GemNotFound     < StandardError; end
  class VersionConflict < StandardError; end

  def self.load(gemfile = nil)
    Environment.new(definition(gemfile))
  end

  def self.definition(gemfile = nil)
    Definition.from_gemfile(gemfile)
  end
end