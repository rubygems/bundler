module Bundler
  class Installer
    def initialize(path)
      if !path.directory?
        raise ArgumentError, "#{path} is not a directory"
      elsif !path.join("cache").directory?
        raise ArgumentError, "#{path} is not a valid environment (it does not contain a cache directory)"
      end

      @path = path
      @gems = Dir[path.join("cache", "*.gem")]
    end

    def install(options = {})
      bin_dir = options[:bin_dir] ||= @path.join("bin")

      # Delete all executables since they will be recreated later
      Dir[bin_dir.join('*')].each { |file| File.delete(file) }

      specs = Dir[File.join(@path, "specifications", "*.gemspec")]
      gems  = Dir[File.join(@path, "gems", "*")]

      @gems.each do |gem|
        name      = File.basename(gem).gsub(/\.gem$/, '')
        installed = specs.any? { |g| File.basename(g) == "#{name}.gemspec" } &&
          gems.any? { |g| File.basename(g) == name }

        unless installed
          Bundler.logger.info "Installing #{name}.gem"
          installer = Gem::Installer.new(gem, :install_dir => @path,
            :ignore_dependencies => true,
            :env_shebang => true,
            :wrappers => true,
            :bin_dir => bin_dir)
          installer.install
        end
      end
    end
  end
end