module Bundler
  class ManifestFileNotFound < StandardError; end

  class Dsl
    def initialize(environment)
      @environment = environment
      @sources = Hash.new { |h,k| h[k] = {} }
      @only, @except, @directory = nil, nil, nil
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

    def directory(path)
      old, @directory = @directory, _combine_directory(path)
      yield
      @directory = old
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

      # OMG REFACTORZ. KTHX
      if options[:vendored_at]
        _handle_vendored_option(name, version, options)
      elsif options[:git]
        _handle_git_option(name, version, options)
      end

      @environment.dependencies << dep
    end

  private

    def _handle_vendored_option(name, version, options)
      vendored_at = Pathname.new(_combine_directory(options[:vendored_at]))
      vendored_at = @environment.filename.dirname.join(vendored_at) if vendored_at.relative?

      if @sources[:directory][vendored_at.to_s]
        raise DirectorySourceError, "There already is a gem defined at '#{vendored_at}'"
      else
        @sources[:directory][vendored_at.to_s] =
          _build_directory_source(name, version) do
            DirectorySource.new(:location => vendored_at)
          end
      end
    end

    def _handle_git_option(name, version, options)
      git = options[:git].to_s

      @sources[:git][git] ||=
        _build_directory_source(name, version) do
          ref = options[:commit] || options[:tag]
          branch = options[:branch]
          GitSource.new(:uri => git, :ref => ref, :branch => branch)
        end
    end

    def _build_directory_source(name, version)
      source = yield
      source.required_specs << name
      source.add_spec(".", name, version) if version
      @environment.add_priority_source(source)
      source
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

    def _combine_directory(path)
      File.join(*[@directory, path].compact)
    end
  end
end
