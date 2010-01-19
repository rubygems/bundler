module Bubble
  class DslError < StandardError; end

  class Dsl
    def self.evaluate(gemfile)
      builder = new
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      builder.to_definition
    end

    def initialize
      @sources = Gem.sources.map { |s| Source::Rubygems.new(:uri => s) }
      @dependencies = []
      @git = nil
      @git_sources = {}
    end

    def gem(name, *args)
      options = Hash === args.last ? args.pop : {}
      version = args.last || ">= 0"

      @dependencies << Dependency.new(name, version, options)
    end

    def source(source)
      source = case source
      when :gemcutter, :rubygems, :rubyforge then Source::Rubygems.new(:uri => "http://gemcutter.org")
      when String then Source::Rubygems.new(:uri => source)
      else source
      end

      @sources << source
    end

    def path(path, options = {})
      source Source::Path.new(options.merge(:path => path))
    end

    def git(uri, options = {})
      source Source::Git.new(options.merge(:uri => uri))
    end

    def to_definition
      Definition.new(@dependencies, @sources)
    end

  end
end