require 'bundler/dependency'

module Bundler
  class Dsl
    def self.evaluate(gemfile, lockfile, unlock)
      builder = new
      builder.instance_eval(Bundler.read_file(gemfile.to_s), gemfile.to_s, 1)
      builder.to_definition(lockfile, unlock)
    end

    VALID_PLATFORMS = Bundler::Dependency::PLATFORM_MAP.keys.freeze

    def initialize
      @rubygems_source = Source::Rubygems.new
      @source          = nil
      @sources         = []
      @dependencies    = []
      @groups          = []
      @platforms       = []
      @env             = nil
    end

    def gemspec(opts = nil)
      path              = opts && opts[:path] || '.'
      name              = opts && opts[:name] || '{,*}'
      development_group = opts && opts[:development_group] || :development
      path              = File.expand_path(path, Bundler.default_gemfile.dirname)
      gemspecs = Dir[File.join(path, "#{name}.gemspec")]

      case gemspecs.size
      when 1
        spec = Bundler.load_gemspec(gemspecs.first)
        raise InvalidOption, "There was an error loading the gemspec at #{gemspecs.first}." unless spec
        gem spec.name, :path => path
        group(development_group) do
          spec.development_dependencies.each do |dep|
            gem dep.name, *(dep.requirement.as_list + [:type => :development])
          end
        end
      when 0
        raise InvalidOption, "There are no gemspecs at #{path}."
      else
        raise InvalidOption, "There are multiple gemspecs at #{path}. Please use the :name option to specify which one."
      end
    end

    def gem(name, *args)
      if name.is_a?(Symbol)
        raise GemfileError, %{You need to specify gem names as Strings. Use 'gem "#{name.to_s}"' instead.}
      end

      options = Hash === args.last ? args.pop : {}
      version = args || [">= 0"]

      _deprecated_options(options)
      _normalize_options(name, version, options)

      dep = Dependency.new(name, version, options)

      # if there's already a dependency with this name we try to prefer one
      if current = @dependencies.find { |d| d.name == dep.name }
        if current.requirement != dep.requirement
          if current.type == :development
            @dependencies.delete current
          elsif dep.type == :development
            return
          else
            raise DslError, "You cannot specify the same gem twice with different version requirements. " \
                            "You specified: #{current.name} (#{current.requirement}) and " \
                            "#{dep.name} (#{dep.requirement})"
          end
        end

        if current.source != dep.source
          if current.type == :development
            @dependencies.delete current
          elsif dep.type == :development
            return
          else
            raise DslError, "You cannot specify the same gem twice coming from different sources. You " \
                            "specified that #{dep.name} (#{dep.requirement}) should come from " \
                            "#{current.source || 'an unspecfied source'} and #{dep.source}"
          end
        end
      end

      @dependencies << dep
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
      unless block_given?
        msg = "You can no longer specify a git source by itself. Instead, \n" \
              "either use the :git option on a gem, or specify the gems that \n" \
              "bundler should find in the git source by passing a block to \n" \
              "the git method, like: \n\n" \
              "  git 'git://github.com/rails/rails.git' do\n" \
              "    gem 'rails'\n" \
              "  end"
        raise DeprecatedError, msg
      end

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
    alias_method :platform, :platforms

    def env(name)
      @env, old = name, @env
      yield
    ensure
      @env = old
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
        raise DeprecatedError, message
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

      invalid_keys = opts.keys - %w(group groups git path name branch ref tag require submodules platform platforms type)
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
      opts["group"] = opts.delete("groups") || opts["group"]
      groups.concat Array(opts.delete("group"))
      groups = [:default] if groups.empty?

      platforms = @platforms.dup
      opts["platforms"] = opts["platform"] || opts["platforms"]
      platforms.concat Array(opts.delete("platforms"))
      platforms.map! { |p| p.to_sym }
      platforms.each do |p|
        next if VALID_PLATFORMS.include?(p)
        raise DslError, "`#{p}` is not a valid platform. The available options are: #{VALID_PLATFORMS.inspect}"
      end

      # Normalize git and path options
      ["git", "path"].each do |type|
        if param = opts[type]
          if version.first && version.first =~ /^\s*=?\s*(\d[^\s]*)\s*$/
            options = opts.merge("name" => name, "version" => $1)
          else
            options = opts.dup
          end
          source = send(type, param, options, :prepend => true) {}
          opts["source"] = source
        end
      end

      opts["source"]  ||= @source
      opts["env"]     ||= @env
      opts["platforms"] = platforms.dup
      opts["group"]     = groups
    end

    def _deprecated_options(options)
      if options.include?(:require_as)
        raise DeprecatedError, "Please replace :require_as with :require"
      elsif options.include?(:vendored_at)
        raise DeprecatedError, "Please replace :vendored_at with :path"
      elsif options.include?(:only)
        raise DeprecatedError, "Please replace :only with :group"
      elsif options.include?(:except)
        raise DeprecatedError, "The :except option is no longer supported"
      end
    end
  end
end
