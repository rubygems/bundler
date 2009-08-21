require "bundler/repository/gem_repository"

module Bundler
  class InvalidRepository < StandardError ; end

  class Repository
    attr_reader :path

    def initialize(path, bindir)
      FileUtils.mkdir_p(path)

      @path   = Pathname.new(path)
      @bindir = Pathname.new(bindir)
      @repo   = Gems.new(@path, @bindir)
    end

    def install(dependencies, finder, options = {})
      if options[:update] || !dependencies.all? { |dep| source_index.search(dep).size > 0 }
        fetch(dependencies, finder)
        expand(options)
      else
        # Remove any gems that are still around if the Gemfile changed without
        # requiring new gems to be download (e.g. a line in the Gemfile was
        # removed)
        cleanup(Resolver.resolve(dependencies, source_index))
      end
      configure(options)
      sync
    end

    def gems
      @repo.gems
    end

    def source_index
      @repo.source_index
    end

    def download_path_for(type)
      @path
    end

  private

    def cleanup(bundle)
      @repo.cleanup(bundle)
    end

    def fetch(dependencies, finder)
      unless bundle = Resolver.resolve(dependencies, finder)
        gems = dependencies.map {|d| "  #{d.to_s}" }.join("\n")
        raise VersionConflict, "No compatible versions could be found for:\n#{gems}"
      end

      # Cleanup here to remove any gems that could cause problem in the expansion
      # phase
      #
      # TODO: Try to avoid double cleanup
      cleanup(bundle)
      bundle.download(self)
    end

    def sync
      glob = gems.map { |g| g.executables }.flatten.join(',')

      (Dir[@bindir.join("*")] - Dir[@bindir.join("{#{glob}}")]).each do |file|
        Bundler.logger.info "Deleting bin file: #{File.basename(file)}"
        FileUtils.rm_rf(file)
      end
    end

    def expand(options)
      @repo.install_cached_gems(:bin_dir => @bindir)
    end

    def configure(options)
      generate_environment(options)
    end

    def generate_environment(options)
      FileUtils.mkdir_p(path)

      specs      = gems
      spec_files = spec_files_for_specs(specs, path)
      load_paths = load_paths_for_specs(specs)
      bindir     = @bindir.relative_path_from(path).to_s
      filename   = options[:manifest].relative_path_from(path).to_s

      File.open(path.join("environment.rb"), "w") do |file|
        template = File.read(File.join(File.dirname(__FILE__), "templates", "environment.erb"))
        erb = ERB.new(template, nil, '-')
        file.puts erb.result(binding)
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

    def require_code(file, dep)
      constraint = case
      when dep.only   then %{ if #{dep.only.inspect}.include?(env)}
      when dep.except then %{ unless #{dep.except.inspect}.include?(env)}
      end
      "require #{file.inspect}#{constraint}"
    end
  end
end