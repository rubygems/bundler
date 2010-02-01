module Bundler
  class DslError < StandardError; end

  class Dsl
    def self.evaluate(gemfile)
      builder = new
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      builder.to_definition
    end

    def initialize
      @sources = [] # Gem.sources.map { |s| Source::Rubygems.new(:uri => s) }
      @dependencies = []
      @group = nil
    end

    def gem(name, *args)
      options = Hash === args.last ? args.pop : {}
      version = args.last || ">= 0"

      _normalize_options(name, version, options)

      @dependencies << Dependency.new(name, version, options)
    end

    def source(source, options = {})
      source = case source
      when :gemcutter, :rubygems, :rubyforge then Source::Rubygems.new(:uri => "http://gemcutter.org")
      when String then Source::Rubygems.new(:uri => source)
      else source
      end

      options[:prepend] ? @sources.unshift(source) : @sources << source
      source
    end

    def path(path, options = {})
      source Source::Path.new(options.merge(:path => path)), options
    end

    def git(uri, options = {})
      source Source::Git.new(options.merge(:uri => uri)), options
    end

    def to_definition
      Definition.new(@dependencies, @sources)
    end

    def group(name, options = {}, &blk)
      old, @group = @group, name
      yield
    ensure
      @group = old
    end

  private

    def _version?(version)
      version && Gem::Version.new(version) rescue false
    end

    def _normalize_options(name, version, opts)
      opts.each do |k, v|
        opts[k.to_s] = v
      end

      opts["group"] ||= @group

      # Normalize git and path options
      ["git", "path"].each do |type|
        if param = opts[type]
          source = send(type, param, opts.merge(:prepend => true))
          source.default_spec name, version if _version?(version)
          opts["source"] = source
        end
      end
    end
  end
end