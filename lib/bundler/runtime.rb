require "digest/sha1"

module Bundler
  class Runtime < Environment
    include SharedHelpers

    def setup(*groups)
      # Has to happen first
      clean_load_path

      specs = groups.any? ? @definition.specs_for(groups) : requested_specs

      setup_environment
      cripple_rubygems(specs)

      # Activate the specs
      specs.each do |spec|
        unless spec.loaded_from
          raise GemNotFound, "#{spec.full_name} is missing. Run `bundle` to get it."
        end

        if activated_spec = Gem.loaded_specs[spec.name] and activated_spec.version != spec.version
          e = Gem::LoadError.new "You have already activated #{activated_spec.name} #{activated_spec.version}, " \
                                 "but your Gemfile requires #{spec.name} #{spec.version}. Consider using bundle exec."
          e.name = spec.name
          e.version_requirement = Gem::Requirement.new(spec.version.to_s)
          raise e
        end

        Gem.loaded_specs[spec.name] = spec
        load_paths = spec.load_paths.reject {|path| $LOAD_PATH.include?(path)}
        $LOAD_PATH.unshift(*load_paths)
      end

      lock

      self
    end

    REGEXPS = [
      /^no such file to load -- (.+)$/i,
      /^Missing \w+ (?:file\s*)?([^\s]+.rb)$/i,
      /^Missing API definition file in (.+)$/i,
      /^cannot load such file -- (.+)$/i,
    ]

    def require(*groups)
      groups.map! { |g| g.to_sym }
      groups = [:default] if groups.empty?

      @definition.dependencies.each do |dep|
        # Skip the dependency if it is not in any of the requested
        # groups
        next unless ((dep.groups & groups).any? && dep.current_platform?)

        required_file = nil

        begin
          # Loop through all the specified autorequires for the
          # dependency. If there are none, use the dependency's name
          # as the autorequire.
          Array(dep.autorequire || dep.name).each do |file|
            required_file = file
            Kernel.require file
          end
        rescue LoadError => e
          REGEXPS.find { |r| r =~ e.message }
          raise if dep.autorequire || $1 != required_file
        end
      end
    end

    def dependencies_for(*groups)
      if groups.empty?
        dependencies
      else
        dependencies.select { |d| (groups & d.groups).any? }
      end
    end

    alias gems specs

    def cache
      FileUtils.mkdir_p(cache_path)

      Bundler.ui.info "Updating .gem files in vendor/cache"
      specs.each do |spec|
        next if spec.name == 'bundler'
        spec.source.cache(spec) if spec.source.respond_to?(:cache)
      end
      prune_cache unless Bundler.settings[:no_prune]
    end

    def prune_cache
      FileUtils.mkdir_p(cache_path)

      resolve = @definition.resolve
      cached  = Dir["#{cache_path}/*.gem"]

      cached = cached.delete_if do |path|
        spec = Gem::Format.from_file_by_path(path).spec

        resolve.any? do |s|
          s.name == spec.name && s.version == spec.version
        end
      end

      if cached.any?
        Bundler.ui.info "Removing outdated .gem files from vendor/cache"

        cached.each do |path|
          Bundler.ui.info "  * #{File.basename(path)}"
          File.delete(path)
        end
      end
    end

    def clean
      return false if Bundler.settings[:path] == nil

      gem_bins             = Dir["#{Gem.dir}/bin/*"]
      git_dirs             = Dir["#{Gem.dir}/bundler/gems/*"]
      gem_dirs             = Dir["#{Gem.dir}/gems/*"]
      spec_gem_paths       = specs.collect {|spec| spec.full_gem_path }
      spec_gem_executables = specs.collect do |spec|
        spec.executables.collect do |executable|
          "#{Gem.dir}/#{spec.bindir}/#{executable}"
        end
      end.flatten
      stale_gem_bins = gem_bins - spec_gem_executables
      stale_git_dirs = git_dirs - spec_gem_paths
      stale_gem_dirs = gem_dirs - spec_gem_paths

      stale_gem_bins.each {|bin| FileUtils.rm(bin) }
      stale_gem_dirs.collect do |gem_dir|
        full_name = Pathname.new(gem_dir).basename.to_s

        FileUtils.rm_rf(gem_dir)
        specification_file = "#{Gem.dir}/specifications/#{full_name}.gemspec"
        FileUtils.rm(specification_file) if File.exists?(specification_file)

        parts   = full_name.split('-')
        name    = parts[0..-2].join('-')
        version = parts.last
        output  = "#{name} (#{version})"

        Bundler.ui.info "Removing #{output}"

        output
      end + stale_git_dirs.collect do |gem_dir|
        full_name = Pathname.new(gem_dir).basename.to_s

        FileUtils.rm_rf(gem_dir)

        parts    = full_name.split('-')
        name     = parts[0..-3].join('-')
        revision = parts[-1]
        version  = parts[-2]
        output   = "#{name} (#{version} #{revision})"

        Bundler.ui.info "Removing #{output}"

        output
      end
    end

  private

    def cache_path
      root.join("vendor/cache")
    end

    def setup_environment
      begin
        ENV["BUNDLE_BIN_PATH"] = Gem.bin_path("bundler", "bundle", VERSION)
      rescue Gem::GemNotFoundException
        ENV["BUNDLE_BIN_PATH"] = File.expand_path("../../../bin/bundle", __FILE__)
      end

      # Set PATH
      paths = (ENV["PATH"] || "").split(File::PATH_SEPARATOR)
      paths.unshift "#{Bundler.bundle_path}/bin"
      ENV["PATH"] = paths.uniq.join(File::PATH_SEPARATOR)

      # Set BUNDLE_GEMFILE
      ENV["BUNDLE_GEMFILE"] = default_gemfile.to_s

      # Set RUBYOPT
      rubyopt = [ENV["RUBYOPT"]].compact
      if rubyopt.empty? || rubyopt.first !~ /-rbundler\/setup/
        rubyopt.unshift "-rbundler/setup"
        rubyopt.unshift "-I#{File.expand_path('../..', __FILE__)}"
        ENV["RUBYOPT"] = rubyopt.join(' ')
      end
    end
  end
end
