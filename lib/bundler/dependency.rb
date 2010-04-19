require 'rubygems/dependency'

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

      if @groups.empty? && !@source
        out <<  "\n"
      else
        out << ":\n"
      end

      out << "    groups: #{@groups.join(", ")}\n" unless @groups.empty?
      out << "    #{@source.to_lock}\n" if @source
      out
    end
  end
end
