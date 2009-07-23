module Bundler
  class ManifestFileNotFound < StandardError; end

  class ManifestBuilder
    def self.build(manifest_file, string)
      builder = new(manifest_file)
      builder.instance_eval(string)
      builder
    end

    def self.load(manifest_file, filename)
      unless File.exist?(filename)
        raise ManifestFileNotFound, "#{filename.inspect} does not exist"
      end
      string = File.read(filename)
      build(manifest_file, string)
    end

    def initialize(manifest_file)
      @manifest_file = manifest_file
    end

    def bundle_path(path)
      path = Pathname.new(path)
      @manifest_file.gem_path = (path.relative? ?
        @manifest_file.root.join(path) : path).expand_path
    end

    def bin_path(path)
      path = Pathname.new(path)
      @manifest_file.bindir = (path.relative? ?
        @manifest_file.root.join(path) : path).expand_path
    end

    def disable_rubygems
      @manifest_file.rubygems = :disable
    end

    def require_rubygems
      @manifest_file.rubygems = :require
    end

    def source(source)
      @manifest_file.sources << source
    end

    def sources
      @manifest_file.sources
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      @manifest_file.dependencies << Dependency.new(name, options.merge(:version => version))
    end
  end
end
