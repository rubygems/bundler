require "rubygems/source_index"

module Bundler
  class VersionConflict < StandardError; end

  class Manifest
    attr_reader :filename, :sources, :dependencies, :path

    def initialize(filename, sources, dependencies, bindir, path, rubygems, system_gems)
      @filename     = filename
      @sources      = sources
      @dependencies = dependencies
      @bindir       = bindir || repository.path.join("bin")
      @path         = path
      @rubygems     = rubygems
      @system_gems  = system_gems
    end

    def install(update)
      repository.install(gem_dependencies, finder, :rubygems => @rubygems, :system_gems => @system_gems, :manifest => @filename)
      Bundler.logger.info "Done."
    end

    def gems
      deps = dependencies
      deps = deps.map { |d| d.to_gem_dependency }
      Resolver.resolve(deps, repository.source_index)
    end

    def environments
      envs = dependencies.map {|dep| Array(dep.only) + Array(dep.except) }.flatten
      envs << "default"
    end

  private

    def finder
      @finder ||= Finder.new(*sources)
    end

    def repository
      @repository ||= Repository.new(@path, @bindir)
    end

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end

    def all_gems_installed?
      downloaded_gems = {}

      Dir[repository.path.join("cache", "*.gem")].each do |file|
        file =~ /\/([^\/]+)-([\d\.]+)\.gem$/
        name, version = $1, $2
        downloaded_gems[name] = Gem::Version.new(version)
      end

      gem_dependencies.all? do |dep|
        downloaded_gems[dep.name] &&
        dep.version_requirements.satisfied_by?(downloaded_gems[dep.name])
      end
    end

    def load_paths_for_specs(specs)
      load_paths = []
      specs.each do |spec|
        gem_path = Pathname.new(spec.full_gem_path)

        if spec.bindir
          load_paths << gem_path.join(spec.bindir).relative_path_from(@path).to_s
        end
        spec.require_paths.each do |path|
          load_paths << gem_path.join(path).relative_path_from(@path).to_s
        end
      end
      load_paths
    end

    def spec_files_for_specs(specs, path)
      files = {}
      specs.each do |s|
        files[s.name] = File.join("specifications", "#{s.full_name}.gemspec")
      end
      files
    end

    def create_bundler_runtime
      here  = Pathname.new(__FILE__).dirname
      there = path.join("bundler")

      Bundler.logger.info "Creating the bundler runtime"

      FileUtils.rm_rf(there)
      there.mkdir
      FileUtils.cp(here.join("runtime.rb"), there)
      FileUtils.cp_r(here.join("runtime"), there)
    end
  end
end
