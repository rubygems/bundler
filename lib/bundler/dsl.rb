module Bundler
  class DslError < StandardError; end

  class Dsl
    def self.evaluate(gemfile)
      builder = new
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      builder.to_definition
    end

    def initialize
      @source  = nil
      @sources = []
      @dependencies = []
      @group = [:default]
    end

    def gem(name, *args)
      options = Hash === args.last ? args.pop : {}
      version = args.last || ">= 0"
      if group = options[:groups] || options[:group]
        options[:group] = group
      end

      _deprecated_options(options)
      _normalize_options(name, version, options)

      @dependencies << Dependency.new(name, version, options)
    end

    def source(source, options = {})
      @source = case source
      when :gemcutter, :rubygems, :rubyforge then Source::Rubygems.new("uri" => "http://gemcutter.org")
      when String then Source::Rubygems.new("uri" => source)
      else source
      end

      options[:prepend] ? @sources.unshift(@source) : @sources << @source

      yield if block_given?
      @source
    ensure
      @source = nil
    end

    def path(path, options = {}, source_options = {}, &blk)
      source Source::Path.new(_normalize_hash(options).merge("path" => Pathname.new(path))), source_options, &blk
    end

    def git(uri, options = {}, source_options = {}, &blk)
      source Source::Git.new(_normalize_hash(options).merge("uri" => uri)), source_options, &blk
    end

    def to_definition
      Definition.new(@dependencies, @sources)
    end

    def group(*args, &blk)
      old, @group = @group, args
      yield
    ensure
      @group = old
    end

    # Deprecated methods

    def self.deprecate(name)
      define_method(name) do |*|
        raise DeprecatedMethod, "#{name} is removed. See the README for more information"
      end
    end

    deprecate :only
    deprecate :except
    deprecate :disable_system_gems
    deprecate :disable_rubygems
    deprecate :clear_sources
    deprecate :bundle_path
    deprecate :bin_path

  private

    def _version?(version)
      version && Gem::Version.new(version) rescue false
    end

    def _normalize_hash(opts)
      # Cannot modify a hash during an iteration in 1.9
      opts.keys.each do |k|
        next if String === k
        v = opts[k]
        opts.delete(k)
        opts[k.to_s] = v
      end
      opts
    end

    def _normalize_options(name, version, opts)
      _normalize_hash(opts)

      group = opts.delete("group") || @group

      # Normalize git and path options
      ["git", "path"].each do |type|
        if param = opts[type]
          options = _version?(version) ? opts.merge("name" => name, "version" => version) : opts.dup
          source = send(type, param, options, :prepend => true)
          opts["source"] = source
        end
      end

      opts["source"] ||= @source

      opts["group"] = group
    end

    def _deprecated_options(options)
      if options.include?(:require_as)
        raise DeprecatedOption, "Please replace :require_as with :require"
      elsif options.include?(:vendored_at)
        raise DeprecatedOption, "Please replace :vendored_at with :path"
      elsif options.include?(:only)
        raise DeprecatedOption, "Please replace :only with :group"
      elsif options.include?(:except)
        raise DeprecatedOption, "The :except option is no longer supported"
      end
    end
  end
end
