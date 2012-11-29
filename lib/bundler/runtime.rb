require "digest/sha1"

module Bundler
  class Runtime < Environment
    include SharedHelpers

    def setup(*groups)
      # Has to happen first
      clean_load_path

      specs = groups.any? ? @definition.specs_for(groups) : requested_specs

      setup_environment
      Bundler.rubygems.replace_entrypoints(specs)

      # Activate the specs
      specs.each do |spec|
        unless spec.loaded_from
          raise GemNotFound, "#{spec.full_name} is missing. Run `bundle` to get it."
        end

        if activated_spec = Bundler.rubygems.loaded_specs(spec.name) and activated_spec.version != spec.version
          e = Gem::LoadError.new "You have already activated #{activated_spec.name} #{activated_spec.version}, " \
                                 "but your Gemfile requires #{spec.name} #{spec.version}. Using bundle exec may solve this."
          e.name = spec.name
          if e.respond_to?(:requirement=)
            e.requirement = Gem::Requirement.new(spec.version.to_s)
          else
            e.version_requirement = Gem::Requirement.new(spec.version.to_s)
          end
          raise e
        end

        Bundler.rubygems.mark_loaded(spec)
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
          if dep.autorequire.nil? && dep.name.include?('-')
            begin
              namespaced_file = dep.name.gsub('-', '/')
              Kernel.require namespaced_file
            rescue LoadError
              REGEXPS.find { |r| r =~ e.message }
              regex_name = $1
              raise if dep.autorequire || (regex_name && regex_name.gsub('-', '/') != namespaced_file)
              raise e if regex_name.nil?
            end
          else
            REGEXPS.find { |r| r =~ e.message }
            raise if dep.autorequire || $1 != required_file
          end
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
      FileUtils.mkdir_p(cache_path) unless File.exists?(cache_path)

      Bundler.ui.info "Updating files in vendor/cache"
      specs.each do |spec|
        next if spec.name == 'bundler'
        spec.source.cache(spec) if spec.source.respond_to?(:cache)
      end
      prune_cache unless Bundler.settings[:no_prune]
    end

    def prune_cache
      FileUtils.mkdir_p(cache_path) unless File.exists?(cache_path)
      resolve = @definition.resolve
      prune_gem_cache(resolve)
      prune_git_and_path_cache(resolve)
    end

    def clean
      gem_bins             = Dir["#{Gem.dir}/bin/*"]
      git_dirs             = Dir["#{Gem.dir}/bundler/gems/*"]
      git_cache_dirs       = Dir["#{Gem.dir}/cache/bundler/git/*"]
      gem_dirs             = Dir["#{Gem.dir}/gems/*"]
      gem_files            = Dir["#{Gem.dir}/cache/*.gem"]
      gemspec_files        = Dir["#{Gem.dir}/specifications/*.gemspec"]
      spec_gem_paths       = []
      # need to keep git sources around
      spec_git_paths       = @definition.sources.select {|s| s.is_a?(Bundler::Source::Git) }.map {|s| s.path.to_s }
      spec_git_cache_dirs  = []
      spec_gem_executables = []
      spec_cache_paths     = []
      spec_gemspec_paths   = []
      specs.each do |spec|
        spec_gem_paths << spec.full_gem_path
        # need to check here in case gems are nested like for the rails git repo
        md = %r{(.+bundler/gems/.+-[a-f0-9]{7,12})}.match(spec.full_gem_path)
        spec_git_paths << md[1] if md
        spec_gem_executables << spec.executables.collect do |executable|
          "#{Bundler.rubygems.gem_bindir}/#{executable}"
        end
        spec_cache_paths << spec.cache_file
        spec_gemspec_paths << spec.spec_file
        spec_git_cache_dirs << spec.source.cache_path.to_s if spec.source.is_a?(Bundler::Source::Git)
      end
      spec_gem_paths.uniq!
      spec_gem_executables.flatten!

      stale_gem_bins       = gem_bins - spec_gem_executables
      stale_git_dirs       = git_dirs - spec_git_paths
      stale_git_cache_dirs = git_cache_dirs - spec_git_cache_dirs
      stale_gem_dirs       = gem_dirs - spec_gem_paths
      stale_gem_files      = gem_files - spec_cache_paths
      stale_gemspec_files  = gemspec_files - spec_gemspec_paths

      stale_gem_bins.each {|bin| FileUtils.rm(bin) }
      output = stale_gem_dirs.collect do |gem_dir|
        full_name = Pathname.new(gem_dir).basename.to_s

        FileUtils.rm_rf(gem_dir)

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
        name     = parts[0..-2].join('-')
        revision = parts[-1]
        output   = "#{name} (#{revision})"

        Bundler.ui.info "Removing #{output}"

        output
      end

      stale_gem_files.each {|file| FileUtils.rm(file) if File.exists?(file) }
      stale_gemspec_files.each {|file| FileUtils.rm(file) if File.exists?(file) }
      stale_git_cache_dirs.each {|dir| FileUtils.rm_rf(dir) if File.exists?(dir) }

      output
    end

    def setup_environment
      begin
        ENV["BUNDLE_BIN_PATH"] = Bundler.rubygems.bin_path("bundler", "bundle", VERSION)
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

  private

    def prune_gem_cache(resolve)
      cached  = Dir["#{cache_path}/*.gem"]

      cached = cached.delete_if do |path|
        spec = Bundler.rubygems.spec_from_gem path

        resolve.any? do |s|
          s.name == spec.name && s.version == spec.version && !s.source.is_a?(Bundler::Source::Git)
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

    def prune_git_and_path_cache(resolve)
      cached  = Dir["#{cache_path}/*/.bundlecache"]

      cached = cached.delete_if do |path|
        name = File.basename(File.dirname(path))

        resolve.any? do |s|
          source = s.source
          source.respond_to?(:app_cache_dirname) && source.app_cache_dirname == name
        end
      end

      if cached.any?
        Bundler.ui.info "Removing outdated .git/path repos from vendor/cache"

        cached.each do |path|
          path = File.dirname(path)
          Bundler.ui.info "  * #{File.basename(path)}"
          FileUtils.rm_rf(path)
        end
      end
    end

    def cache_path
      root.join("vendor/cache")
    end
  end
end
