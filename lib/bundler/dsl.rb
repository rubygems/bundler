module Bundler
  class ManifestFileNotFound < StandardError; end

  class Dsl
    def initialize(environment)
      @environment  = environment
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
      source = Source.new(:uri => source)
      unless @environment.sources.include?(source)
        @environment.add_source(source)
      end
    end

    def clear_sources
      @environment.clear_sources
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      dep = Dependency.new(name, options.merge(:version => version))

      if vendored_at = options[:vendored_at]
        raise ArgumentError, "If you use :at, you must specify the gem and version you wish to stand in for" unless version

        begin
          Gem::Version.new(version)
        rescue ArgumentError
          raise ArgumentError, "If you use :at, you must specify a gem and version. You specified #{version} for the version"
        end

        vendored_at = Pathname.new(vendored_at)
        vendored_at = @environment.filename.dirname.join(vendored_at) if vendored_at.relative?

        source = DirectorySource.new(
          :name     => name,
          :version  => version,
          :location => vendored_at
        )

        @environment.add_priority_source(source)
      end

      @environment.dependencies << dep
    end
  end
end
