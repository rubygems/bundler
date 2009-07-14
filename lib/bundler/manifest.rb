require "rubygems/source_index"
require "pathname"

module Bundler
  class VersionConflict < StandardError; end

  class Manifest
    attr_reader :sources, :dependencies

    def initialize(sources, dependencies, path)
      sources.map! {|s| s.is_a?(URI) ? s : URI.parse(s) }
      @sources, @dependencies, @path = sources, dependencies, Pathname.new(path)
    end

    def fetch
      return if all_gems_installed?

      finder = Finder.new(*sources)
      unless bundle = finder.resolve(*gem_dependencies)
        gems = @dependencies.map {|d| "  #{d.to_s}" }.join("\n")
        raise VersionConflict, "No compatible versions could be found for:\n#{gems}"
      end

      bundle.download(@path)
    end

    def install
      fetch
      installer = Installer.new(@path)
      installer.install  # options come here
    end

    def activate
      index = Gem::SourceIndex.from_gems_in(@path.join("specifications"))
      index.each do |name, spec|
        $:.unshift File.join(spec.full_gem_path, spec.bindir)
        spec.require_paths.each {|p| $:.unshift File.join(spec.full_gem_path, p) }
      end
    end

    def require_all
      dependencies.each do |dep|
        dep.require_as.each {|file| require file }
      end
    end

  private

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end

    def all_gems_installed?
      gem_versions = {}

      Dir[File.join(@path, "cache", "*.gem")].each do |file|
        file =~ /\/([^\/]+)-([\d\.]+)\.gem$/
        name, version = $1, $2
        gem_versions[name] = Gem::Version.new(version)
      end

      ret = gem_dependencies.all? do |dep|
        dep.version_requirements.satisfied_by?(gem_versions[dep.name])
      end
    end
  end
end