require "uri"
require "rubygems/spec_fetcher"

module Bundler
  class LazySpecification
    attr_reader :name, :version, :dependencies, :platform
    attr_accessor :source

    def initialize(name, version, platform)
      @name         = name
      @version      = version
      @dependencies = []
      @platform     = platform
      @source       = nil
    end

    def full_name
      if platform == Gem::Platform::RUBY or platform.nil? then
        "#{@name}-#{@version}"
      else
        "#{@name}-#{@version}-#{platform}"
      end
    end

    def satisfies?(dependency)
      @name == dependency.name && dependency.requirement.satisfied_by?(Gem::Version.new(@version))
    end

    def __materialize__(index)
      @specification = index.search(self).first
      raise "Could not materialize #{full_name}" unless @specification
    end

    def respond_to?(*args)
      super || @specification.respond_to?(*args)
    end

  private

    def method_missing(method, *args, &blk)
      if Gem::Specification.new.respond_to?(method)
        raise "LazySpecification has not been materialized yet" unless @specification
        @specification.send(method, *args, &blk)
      else
        super
      end
    end

  end
end