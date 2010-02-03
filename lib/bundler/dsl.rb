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
      when :gemcutter, :rubygems, :rubyforge then Source::Rubygems.new("uri" => "http://gemcutter.org")
      when String then Source::Rubygems.new("uri" => source)
      else source
      end

      options[:prepend] ? @sources.unshift(source) : @sources << source
      source
    end

    def path(path, options = {}, source_options = {})
      source Source::Path.new(_normalize_hash(options).merge("path" => path)), source_options
    end

    def git(uri, options = {}, source_options = {})
      source Source::Git.new(_normalize_hash(options).merge("uri" => uri)), source_options
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

    def _normalize_hash(opts)
      opts.each do |k, v|
        next if String === k
        opts.delete(k)
        opts[k.to_s] = v
      end
    end

    def _normalize_options(name, version, opts)
      _normalize_hash(opts)

      group = opts.delete("group") || @group

      # Normalize git and path options
      ["git", "path"].each do |type|
        if param = opts[type]
          source = send(type, param, opts.dup, :prepend => true)
          source.default_spec name, version if _version?(version)
          opts["source"] = source
        end
      end

      opts["group"] = group
    end
  end
end