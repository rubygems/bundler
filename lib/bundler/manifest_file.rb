module Bundler
  class DefaultManifestNotFound < StandardError; end

  class ManifestFile
    attr_reader :dependencies
    attr_accessor :gem_path, :bindir, :rubygems, :system_gems

    def self.load(filename = nil)
      new(filename).load
    end

    def initialize(filename)
      @filename        = filename
      @default_sources = [Source.new("http://gems.rubyforge.org")]
      @sources         = []
      @dependencies    = []
      @rubygems        = true
      @system_gems     = true
    end

    def load
      manifest
      self
    end

    def manifest
      @manifest ||= load_manifest
    end

    def install(update = false)
      manifest.install(update)
    end

    def sources
      @sources + @default_sources
    end

    def add_source(source)
      @sources << source
    end

    def clear_sources
      @sources.clear
      @default_sources.clear
    end

    def setup_environment
      unless @system_gems
        ENV["GEM_HOME"] = @gem_path
        ENV["GEM_PATH"] = @gem_path
      end
      ENV["PATH"]     = "#{@bindir}:#{ENV["PATH"]}"
      ENV["RUBYOPT"]  = "-r#{@gem_path}/environment #{ENV["RUBYOPT"]}"
    end

    def load_manifest
      ManifestBuilder.load(self, filename)
      Manifest.new(filename, sources, dependencies, bindir, gem_path, rubygems, system_gems)
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
      Pathname.new(@filename ||= find_manifest_file)
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
