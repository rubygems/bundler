module Bubble
  class DslError < StandardError; end

  class Dsl
    def self.evaluate(gemfile, definition)
      builder = new(definition)
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      definition
    end

    def initialize(definition)
      @definition = definition
      @git = nil
      @git_sources = {}
    end

    def gem(name, *args)
      options = Hash === args.last ? args.pop : {}
      version = args.last || ">= 0"

      @definition.dependencies << Dependency.new(name, version, options)
    end

    def source(source)
      source = case source
      when :gemcutter, :rubygems, :rubyforge then Source::Rubygems.new(:uri => "http://gemcutter.org")
      when String then Source::Rubygems.new(:uri => source)
      else source
      end

      @definition.sources << source
    end

    def path(path, options = {})
      source Source::Path.new(options.merge(:path => path))
    end

    def git(uri, options = {})
      source Source::Git.new(options.merge(:uri => uri))
    end

  end
end