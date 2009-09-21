module Bundler
  class Repository
    class Gems
      attr_reader :path, :bindir

      def initialize(path, bindir)
        @path   = path
        @bindir = bindir
      end

      # Checks whether a gem is installed
      def expand(options)
        cached_gems.each do |name, version|
          unless installed?(name, version)
            install_cached_gem(name, version, options)
          end
        end
      end

      def download_path_for
        path
      end

    private

      def cache_path
        @path.join("cache")
      end

      def cache_files
        Dir["#{cache_path}/*.gem"]
      end

      def cached_gems
        cache_files.map do |f|
          full_name = File.basename(f).gsub(/\.gem$/, '')
          full_name.split(/-(?=[^-]+$)/)
        end
      end

      def spec_path
        @path.join("specifications")
      end

      def spec_files
        Dir["#{spec_path}/*.gemspec"]
      end

      def gem_path
        @path.join("gems")
      end

      def gem_paths
        Dir["#{gem_path}/*"]
      end

      def installed?(name, version)
        spec_files.any? { |g| File.basename(g) == "#{name}-#{version}.gemspec" } &&
          gem_paths.any? { |g| File.basename(g) == "#{name}-#{version}" }
      end

      def install_cached_gem(name, version, options = {})
        cached_gem = cache_path.join("#{name}-#{version}.gem")
        # TODO: Add a warning if cached_gem is not a file
        if cached_gem.file?
          Bundler.logger.info "Installing #{name}-#{version}.gem"
          installer = Gem::Installer.new(cached_gem.to_s, options.merge(
            :install_dir         => @path,
            :ignore_dependencies => true,
            :env_shebang         => true,
            :wrappers            => true,
            :bin_dir             => @bindir
          ))
          installer.install
        end
      end
    end
  end
end
