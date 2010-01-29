require 'rubygems/dependency'

module Bundler
  class Dependency < Gem::Dependency
    attr_accessor :source

    def initialize(name, version, options = {}, &blk)
      super(name, version)

      @group = options["group"]
    end
  end
end