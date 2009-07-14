module Bundler
  class VersionConflict < StandardError; end

  class Manifest
    attr_reader :sources, :dependencies

    def initialize(sources, dependencies, path)
      sources.map! {|s| s.is_a?(URI) ? s : URI.parse(s) }
      @sources, @dependencies, @path = sources, dependencies, path
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