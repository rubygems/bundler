require 'rubygems/dependency'
require 'bundler/shared_helpers'

module Bundler
  class Dependency < Gem::Dependency
    attr_reader :autorequire
    attr_reader :groups

    def initialize(name, version, options = {}, &blk)
      super(name, version)

      @autorequire = nil
      @groups      = Array(options["group"] || :default).map { |g| g.to_sym }
      @source      = options["source"]

      if options.key?('require')
        @autorequire = Array(options['require'] || [])
      end
    end

    def to_lock
      out = "  #{name}"
      unless requirement == Gem::Requirement.default
        out << " (#{requirement.to_s})"
      end

      if @source
        out << ":\n    #{@source.to_lock}\n"
      else
        out << "\n"
      end
    end
  end
end
