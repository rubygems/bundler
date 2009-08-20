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
      repository.install(gem_dependencies, Finder.new(*sources),
        :rubygems    => @rubygems,
        :system_gems => @system_gems,
        :manifest    => @filename,
        :update      => update
      )
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

    def repository
      @repository ||= Repository.new(@path, @bindir)
    end

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end
  end
end
