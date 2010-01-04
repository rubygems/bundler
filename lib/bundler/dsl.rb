module Bundler
  class ManifestFileNotFound < StandardError; end
  class InvalidKey < StandardError; end
  class DefaultManifestNotFound < StandardError; end

  class Dsl
    def self.evaluate(file, bundle, environment)
      builder = new(bundle, environment)
      builder.instance_eval(File.read(file.to_s), file.to_s, 1)
      environment
    end

    def initialize(bundle, environment)
      @bundle = bundle
      @environment = environment
      @directory_sources = []
      @git_sources = {}
      @only, @except, @directory, @git = nil, nil, nil, nil
    end

    def bundle_path(path)
      @bundle.path = Pathname.new(path)
    end

    def bin_path(path)
      @bundle.bindir = Pathname.new(path)
    end

    def disable_rubygems
      @environment.rubygems = false
    end

    def disable_system_gems
      @environment.system_gems = false
    end

    def source(source)
      source = GemSource.new(@bundle, :uri => source)
      unless @environment.sources.include?(source)
        @environment.add_source(source)
      end
    end

    def only(*env)
      old, @only = @only, _combine_only(env)
      yield
      @only = old
    end

    def except(*env)
      old, @except = @except, _combine_except(env)
      yield
      @except = old
    end

    def directory(path, options = {})
      raise DirectorySourceError, "cannot nest calls to directory or git" if @directory || @git
      @directory = DirectorySource.new(@bundle, options.merge(:location => path))
      @directory_sources << @directory
      @environment.add_priority_source(@directory)
      retval = yield if block_given?
      @directory = nil
      retval
    end

    def git(uri, options = {})
      raise DirectorySourceError, "cannot nest calls to directory or git" if @directory || @git
      @git = GitSource.new(@bundle, options.merge(:uri => uri))
      @git_sources[uri] = @git
      @environment.add_priority_source(@git)
      retval = yield if block_given?
      @git = nil
      retval
    end

    def clear_sources
      @environment.clear_sources
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      keys = :vendored_at, :path, :only, :except, :git, :path, :bundle, :require_as, :tag, :branch, :ref
      unless (invalid = options.keys - keys).empty?
        raise InvalidKey, "Only #{keys.join(", ")} are valid options to #gem. You used #{invalid.join(", ")}"
      end

      if path = options.delete(:vendored_at)
        options[:path] = path
        warn "The :vendored_at option is deprecated. Use :path instead.\nFrom #{caller[0]}"
      end

      options[:only] = _combine_only(options[:only] || options["only"])
      options[:except] = _combine_except(options[:except] || options["except"])

      dep = Dependency.new(name, options.merge(:version => version))

      if options.key?(:bundle) && !options[:bundle]
        dep.source = SystemGemSource.new(@bundle)
      elsif @git || options[:git]
        dep.source = _handle_git_option(name, version, options)
      elsif @directory || options[:path]
        dep.source = _handle_vendored_option(name, version, options)
      end

      @environment.dependencies << dep
    end

  private

    def _version?(version)
      version && Gem::Version.new(version) rescue false
    end

    def _handle_vendored_option(name, version, options)
      dir, path = _find_directory_source(options[:path])

      if dir
        dir.required_specs << name
        dir.add_spec(path, name, version) if _version?(version)
        dir
      else
        directory options[:path] do
          _handle_vendored_option(name, version, {})
        end
      end
    end

    def _find_directory_source(path)
      if @directory
        return @directory, Pathname.new(path || '')
      end

      path = @bundle.gemfile.dirname.join(path)

      @directory_sources.each do |s|
        if s.location.expand_path.to_s < path.expand_path.to_s
          return s, path.relative_path_from(s.location)
        end
      end

      nil
    end

    def _handle_git_option(name, version, options)
      git    = options[:git].to_s
      ref    = options[:ref] || options[:tag]
      branch = options[:branch]

      if source = @git || @git_sources[git]
        if ref && source.ref != ref
          raise GitSourceError, "'#{git}' already specified with ref: #{source.ref}"
        elsif branch && source.branch != branch
          raise GitSourceError, "'#{git}' already specified with branch: #{source.branch}"
        end

        source.required_specs << name
        source.add_spec(Pathname.new(options[:path] || '.'), name, version) if _version?(version)
        source
      else
        git(git, :ref => ref, :branch => branch) do
          _handle_git_option(name, version, options)
        end
      end
    end

    def _combine_only(only)
      return @only unless only
      only = Array(only).compact.uniq.map { |o| o.to_s }
      only &= @only if @only
      only
    end

    def _combine_except(except)
      return @except unless except
      except = Array(except).compact.uniq.map { |o| o.to_s }
      except |= @except if @except
      except
    end
  end
end
