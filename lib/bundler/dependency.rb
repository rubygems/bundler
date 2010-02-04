require 'rubygems/dependency'

module Bundler
  class Dependency < Gem::Dependency
    attr_reader :autorequire

    def initialize(name, version, options = {}, &blk)
      super(name, version)

      @groups = Array(options["group"] || :default)
      @source = options["source"]
      @autorequire = options.include?("require") ? options['require'] || [] : [name]
      @autorequire = [@autorequire] unless @autorequire.is_a?(Array)
    end
  end
end
