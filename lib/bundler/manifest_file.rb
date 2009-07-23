module Bundler
  class DefaultManifestNotFound < StandardError; end

  class ManifestFile
    attr_reader :sources, :dependencies
    attr_accessor :gem_path, :bindir

    def self.load(filename = nil)
      new(filename).load
    end

    def initialize(filename)
      @filename = filename
      @sources       = %w(http://gems.rubyforge.org)
      @dependencies  = []
    end

    def load
      manifest
      self
    end

    def manifest
      @manifest ||= load_manifest
    end

    def install
      manifest.install
    end

    def setup_environment
      manifest.setup_environment
    end

    def load_manifest
      ManifestBuilder.load(self, filename)
      Manifest.new(sources, dependencies, bindir, gem_path)
    end

    def gem_path
      @gem_path ||= root.join("vendor", "gems")
    end

    def bindir
      @bindir ||= root.join("bin")
    end

    def root
      filename.parent
    end

    def filename
      @filename ||= find_manifest_file
    end

    def find_manifest_file
      current = Pathname.new(Dir.pwd)

      until current.root?
        filename = current.join("Gemfile")
        return filename if filename.exist?
        current = current.parent
      end

      raise DefaultManifestNotFound
    end
  end
end
