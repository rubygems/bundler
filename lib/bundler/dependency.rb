require 'rubygems/dependency'

module Bundler
  class Dependency < Gem::Dependency
    attr_accessor :source

    def initialize(name, version, options = {}, &blk)
      options.each do |k, v|
        options[k.to_s] = v
      end

      super(name, version)
    end
  end
end