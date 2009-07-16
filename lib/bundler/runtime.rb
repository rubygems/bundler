module Bundler
  class ManifestBuilder

    def self.build(path, string)
      builder = new(path)
      builder.instance_eval(string)
      builder.to_manifest
    end

    def initialize(path)
      @path         = path
      @sources      = %w(http://gems.rubyforge.org)
      @dependencies = []
    end

    def to_manifest
      Manifest.new(@sources, @dependencies, @path)
    end

    def source(source)
      @sources << source
    end

    def gem(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      version = args.last

      @dependencies << Dependency.new(name, :version => version)
    end

  end
end