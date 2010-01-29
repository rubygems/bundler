require 'rubygems/dependency'

module Bundler
  class Dependency < Gem::Dependency
    def initialize(name, version, options = {}, &blk)
      super(name, version)

      @group  = options["group"] || :default
      @source = options["source"]
    end
  end
end