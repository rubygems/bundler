module Bundler
  class ManifestFileNotFound < StandardError; end

  class Dsl
    def initialize(environment)
      @environment = environment
      @sources = Hash.new { |h,k| h[k] = {} }
      @only, @except = nil, nil
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

    def only(env)
      old, @only = @only, _combine_onlys(env)
      yield
      @only = old
    end

    def except(env)
      old, @except = @except, _combine_excepts(env)
      yield
      @except = old
    end

    def clear_sources
      @environment.clear_sources
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      options[:only] = _combine_onlys(options[:only] || options["only"])
      options[:except] = _combine_excepts(options[:except] || options["except"])

      dep = Dependency.new(name, options.merge(:version => version))

      # OMG REFACTORZ. KTHX
      if vendored_at = options[:vendored_at]
        vendored_at = Pathname.new(vendored_at)
        vendored_at = @environment.filename.dirname.join(vendored_at) if vendored_at.relative?

        @sources[:directory][vendored_at.to_s] ||= begin
          source = DirectorySource.new(:location => vendored_at)
          source.required_specs << name
          source.add_spec(".", name, version) if version
          @environment.add_priority_source(source)
          source
        end
      elsif git = options[:git]
        @sources[:git][git] ||= begin
          source = GitSource.new(
            :uri     => git,
            :ref     => options[:commit] || options[:tag],
            :branch  => options[:branch]
          )
          source.required_specs << name
          source.add_spec(".", name, version) if version
          @environment.add_priority_source(source)
          source
        end
      end

      @environment.dependencies << dep
    end

  private

    def _combine_onlys(only)
      return @only unless only
      only = [only].flatten.compact.uniq.map { |o| o.to_s }
      only &= @only if @only
      only
    end

    def _combine_excepts(except)
      return @except unless except
      except = [except].flatten.compact.uniq.map { |o| o.to_s }
      except |= @except if @except
      except
    end
  end
end
