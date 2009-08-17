require "rubygems/source_index"

module Bundler
  class VersionConflict < StandardError; end

  class Manifest
    attr_reader :sources, :dependencies, :path

    def initialize(sources, dependencies, bindir, path, rubygems, system_gems)
      @sources      = sources
      @dependencies = dependencies
      @bindir       = bindir
      @path         = path
      @rubygems     = rubygems
      @system_gems  = system_gems
    end

    def install(update)
      fetch(update)
      repository.install_cached_gems(:bin_dir => @bindir || repository.path.join("bin"))
      repository.cleanup(gems)
      create_environment_files(repository.path.join("environments"))
      Bundler.logger.info "Done."
    end

    def activate(environment = "default")
      require repository.path.join("environments", "#{environment}.rb")
    end

    def require_all
      dependencies.each do |dep|
        dep.require_as.each {|file| require file }
      end
    end

    def gems_for(environment = nil)
      deps     = dependencies
      deps     = deps.select { |d| d.in?(environment) } if environment
      deps     = deps.map { |d| d.to_gem_dependency }
      Resolver.resolve(deps, repository.source_index)
    end
    alias gems gems_for

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

    def fetch(update)
      return unless update || !all_gems_installed?

      unless bundle = Resolver.resolve(gem_dependencies, finder)
        gems = @dependencies.map {|d| "  #{d.to_s}" }.join("\n")
        raise VersionConflict, "No compatible versions could be found for:\n#{gems}"
      end

      bundle.download(repository)
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

    def create_environment_files(path)
      FileUtils.mkdir_p(path)
      environments.each do |environment|
        specs = gems_for(environment)
        files = spec_files_for_specs(specs, path)
        load_paths = load_paths_for_specs(specs)
        create_environment_file(path, environment, files, load_paths)
      end
    end

    def create_environment_file(path, environment, spec_files, load_paths)
      File.open(path.join("#{environment}.rb"), "w") do |file|
        template = File.read(File.join(File.dirname(__FILE__), "templates", "environment.rb"))
        erb = ERB.new(template)
        file.puts erb.result(binding)
      end
    end

    def load_paths_for_specs(specs)
      load_paths = []
      specs.each do |spec|
        load_paths << File.join(spec.full_gem_path, spec.bindir) if spec.bindir
        spec.require_paths.each do |path|
          load_paths << File.join(spec.full_gem_path, path)
        end
      end
      load_paths
    end

    def spec_files_for_specs(specs, path)
      files = {}
      specs.each do |s|
        files[s.name] = path.join("..", "specifications", "#{s.full_name}.gemspec").expand_path
      end
      files
    end
  end
end
