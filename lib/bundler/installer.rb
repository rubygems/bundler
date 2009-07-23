module Bundler
  class Installer
    def self.install(gem_path, bindir = nil)
      new(gem_path, bindir).install
    end

    def initialize(gem_path, bindir)
      if !gem_path.directory?
        raise ArgumentError, "#{gem_path} is not a directory"
      elsif !gem_path.join("cache").directory?
        raise ArgumentError, "#{gem_path} is not a valid environment (it does not contain a cache directory)"
      end

      @gem_path = gem_path

      @bindir = bindir || gem_path.join("bin")
      @gems = Dir[@gem_path.join("cache", "*.gem")]
    end

    def install
      specs = Dir[File.join(@gem_path, "specifications", "*.gemspec")]
      gems  = Dir[File.join(@gem_path, "gems", "*")]

      @gems.each do |gem|
        name      = File.basename(gem).gsub(/\.gem$/, '')
        installed = specs.any? { |g| File.basename(g) == "#{name}.gemspec" } &&
          gems.any? { |g| File.basename(g) == name }

        unless installed
          Bundler.logger.info "Installing #{name}.gem"
          installer = Gem::Installer.new(gem, :install_dir => @gem_path,
            :ignore_dependencies => true,
            :env_shebang => true,
            :wrappers => true,
            :bin_dir => @bindir)
          installer.install
        end
      end
      self
    end
  end
end
