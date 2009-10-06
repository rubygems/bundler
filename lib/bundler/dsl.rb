module Bundler
  class ManifestFileNotFound < StandardError; end

  class Dsl
    def initialize(environment)
      @environment = environment
      @directory_sources = []
      @git_sources = {}
      @only, @except, @directory, @git = nil, nil, nil, nil
    end

    def bundle_path(path)
      path = Pathname.new(path)
      @environment.gem_path = (path.relative? ?
        @environment.root.join(path) : path).expand_path
    end

    def bin_path(path)
      path = Pathname.new(path)
      @environment.bindir = (path.relative? ?
        @environment.root.join(path) : path).expand_path
    end

    def disable_rubygems
      @environment.rubygems = false
    end

    def disable_system_gems
      @environment.system_gems = false
    end

    def source(source)
      source = GemSource.new(:uri => source)
      unless @environment.sources.include?(source)
        @environment.add_source(source)
      end
    end

    def only(*env)
      old, @only = @only, _combine_only(env.flatten)
      yield
      @only = old
    end

    def except(*env)
      old, @except = @except, _combine_except(env.flatten)
      yield
      @except = old
    end

    def directory(path, options = {})
      raise DirectorySourceError, "cannot nest calls to directory or git" if @directory || @git
      @directory = DirectorySource.new(options.merge(:location => path))
      @directory_sources << @directory
      @environment.add_priority_source(@directory)
      yield if block_given?
      @directory = nil
    end

    def git(uri, options = {})
      raise DirectorySourceError, "cannot nest calls to directory or git" if @directory || @git
      @git = GitSource.new(options.merge(:uri => uri))
      @git_sources[uri] = @git
      @environment.add_priority_source(@git)
      yield if block_given?
      @git = nil
    end

    def clear_sources
      @environment.clear_sources
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      options[:only] = _combine_only(options[:only] || options["only"])
      options[:except] = _combine_except(options[:except] || options["except"])

      dep = Dependency.new(name, options.merge(:version => version))

      if @git || options[:git]
        _handle_git_option(name, version, options)
      elsif @directory || options[:vendored_at]
        _handle_vendored_option(name, version, options)
      end

      @environment.dependencies << dep
    end

  private

    def _handle_vendored_option(name, version, options)
      dir, path = _find_directory_source(options[:vendored_at])

      if dir
        dir.required_specs << name
        dir.add_spec(path, name, version) if version
      else
        directory options[:vendored_at] do
          _handle_vendored_option(name, version, {})
        end
      end
    end

    def _find_directory_source(path)
      if @directory
        return @directory, Pathname.new(path || '')
      end

      path = @environment.filename.dirname.join(path)

      @directory_sources.each do |s|
        if s.location.expand_path.to_s < path.expand_path.to_s
          return s, path.relative_path_from(s.location)
        end
      end

      nil
    end

    def _handle_git_option(name, version, options)
      git    = options[:git].to_s
      ref    = options[:commit] || options[:tag]
      branch = options[:branch]

      if source = @git || @git_sources[git]
        if ref && source.ref != ref
          raise GitSourceError, "'#{git}' already specified with ref: #{source.ref}"
        elsif branch && source.branch != branch
          raise GitSourceError, "'#{git}' already specified with branch: #{source.branch}"
        end

        source.required_specs << name
        source.add_spec(Pathname.new(options[:vendored_at] || '.'), name, version) if version
      else
        git(git, :ref => ref, :branch => branch) do
          _handle_git_option(name, version, options)
        end
      end
    end

    def _combine_only(only)
      return @only unless only
      only = [only].flatten.compact.uniq.map { |o| o.to_s }
      only &= @only if @only
      only
    end

    def _combine_except(except)
      return @except unless except
      except = [except].flatten.compact.uniq.map { |o| o.to_s }
      except |= @except if @except
      except
    end
  end
end
