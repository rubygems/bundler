module Bundler
  class DslError < StandardError; end

  class Dsl
    def self.evaluate(gemfile)
      builder = new
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      builder.to_definition
    end

    VALID_PLATFORMS = [:ruby_18, :ruby_19, :ruby, :jruby, :mswin]

    def initialize
      @rubygems_source = Source::Rubygems.new
      @source          = nil
      @sources         = []
      @dependencies    = []
      @groups          = []
      @platforms       = []
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
      case source
      when :gemcutter, :rubygems, :rubyforge then
        rubygems_source "http://rubygems.org"
        return
      when String
        rubygems_source source
        return
      end

      @source = source
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

    def to_definition(lockfile, unlock)
      @sources << @rubygems_source
      @sources.uniq!
      Definition.new(lockfile, @dependencies, @sources, unlock)
    end

    def group(*args, &blk)
      @groups.concat args
      yield
    ensure
      args.each { @groups.pop }
    end

    def platforms(*platforms)
      @platforms.concat platforms
      yield
    ensure
      platforms.each { @platforms.pop }
    end

    # Deprecated methods

    def self.deprecate(name, replacement = nil)
      define_method(name) do |*|
        message = "'#{name}' has been removed from the Gemfile DSL, "
        if replacement
          message << "and has been replaced with '#{replacement}'."
        else
          message << "and is no longer supported."
        end
        message << "\nSee the README for more information on upgrading from Bundler 0.8."
        raise DeprecatedMethod, message
      end
    end

    deprecate :only, :group
    deprecate :except
    deprecate :disable_system_gems
    deprecate :disable_rubygems
    deprecate :clear_sources
    deprecate :bundle_path
    deprecate :bin_path

  private

    def rubygems_source(source)
      @rubygems_source.add_remote source
      @sources << @rubygems_source
    end

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

      invalid_keys = opts.keys - %w(group git path name branch ref tag require)
      if invalid_keys.any?
        plural = invalid_keys.size > 1
        message = "You passed #{invalid_keys.map{|k| ':'+k }.join(", ")} "
        if plural
          message << "as options for gem '#{name}', but they are invalid."
        else
          message << "as an option for gem '#{name}', but it is invalid."
        end
        raise InvalidOption, message
      end

      groups = @groups.dup
      groups.concat Array(opts.delete("group"))
      groups = [:default] if groups.empty?

      platforms = @platforms.dup
      platforms.concat Array(opts.delete("platforms"))
      platforms.map! { |p| p.to_sym }
      platforms.each do |p|
        next if VALID_PLATFORMS.include?(p)
        raise DslError, "`#{p}` is not a valid platform. The available options are: #{VALID_PLATFORMS.inspect}"
      end

      # Normalize git and path options
      ["git", "path"].each do |type|
        if param = opts[type]
          options = _version?(version) ? opts.merge("name" => name, "version" => version) : opts.dup
          source = send(type, param, options, :prepend => true)
          opts["source"] = source
        end
      end

      opts["source"] ||= @source

      opts["platforms"] = @platforms.dup
      opts["group"] = groups
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
