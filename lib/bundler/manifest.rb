require "rubygems/source_index"

module Bundler
  class VersionConflict < StandardError; end

  class Manifest
    attr_reader :sources, :dependencies, :path

    def initialize(sources, dependencies, bindir, gem_path, rubygems)
      sources.map! {|s| s.is_a?(URI) ? s : URI.parse(s) }
      @sources      = sources
      @dependencies = dependencies
      @bindir       = bindir
      @gem_path     = gem_path
      @rubygems     = rubygems
    end

    def install
      fetch
      Installer.install(@gem_path, @bindir)
      cleanup_removed_gems
      create_load_paths_files(@gem_path.join("environments"))
      create_fake_rubygems(@gem_path.join("environments"))
      Bundler.logger.info "Done."
    end

    def activate(environment = "default")
      require @gem_path.join("environments", "#{environment}.rb")
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
      index    = Gem::SourceIndex.from_gems_in(@gem_path.join("specifications"))
      Resolver.resolve(deps, index)
    end
    alias gems gems_for

    def environments
      envs = dependencies.map {|dep| Array(dep.only) + Array(dep.except) }.flatten
      envs << "default"
    end

  private

    def fetch
      return if all_gems_installed?

      finder = Finder.new(*sources)
      unless bundle = finder.resolve(*gem_dependencies)
        gems = @dependencies.map {|d| "  #{d.to_s}" }.join("\n")
        raise VersionConflict, "No compatible versions could be found for:\n#{gems}"
      end

      bundle.download(@gem_path)
    end

    def gem_dependencies
      @gem_dependencies ||= dependencies.map { |d| d.to_gem_dependency }
    end

    def all_gems_installed?
      downloaded_gems = {}

      Dir[@gem_path.join("cache", "*.gem")].each do |file|
        file =~ /\/([^\/]+)-([\d\.]+)\.gem$/
        name, version = $1, $2
        downloaded_gems[name] = Gem::Version.new(version)
      end

      gem_dependencies.all? do |dep|
        downloaded_gems[dep.name] &&
        dep.version_requirements.satisfied_by?(downloaded_gems[dep.name])
      end
    end

    def cleanup_removed_gems
      glob = gems.map { |g| g.full_name }.join(',')
      base = @gem_path.join("{cache,specifications,gems}")

      (Dir[base.join("*")] - Dir[base.join("{#{glob}}{.gemspec,.gem,}")]).each do |file|
        Bundler.logger.info "Deleting gem: #{File.basename(file, ".gem")}" if File.basename(file) =~ /\.gem$/
        FileUtils.rm_rf(file)
      end

      glob = gems.map { |g| g.executables }.flatten.join(',')
      (Dir[@bindir.join("*")] - Dir[@bindir.join("{#{glob}}")]).each do |file|
        Bundler.logger.info "Deleting bin file: #{File.basename(file)}"
        FileUtils.rm_rf(file)
      end
    end

    def create_load_paths_files(path)
      FileUtils.mkdir_p(path)
      environments.each do |environment|
        specs = gems_for(environment)
        files = spec_files_for_specs(specs, path)
        load_paths = load_paths_for_specs(specs)
        create_load_path_file(path, environment, files, load_paths)
      end
    end

    def create_load_path_file(path, environment, spec_files, load_paths)
      File.open(path.join("#{environment}.rb"), "w") do |file|
        template = File.read(File.join(File.dirname(__FILE__), "templates", "environment.rb"))
        erb = ERB.new(template)
        file.puts erb.result(binding)
      end
    end

    def create_fake_rubygems(path)
      File.open(path.join("rubygems.rb"), "w") do |file|
        template = File.read(File.join(File.dirname(__FILE__), "templates", "rubygems.rb"))
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
