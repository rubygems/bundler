require "digest/sha1"

module Bundler
  class Runtime < Environment
    include SharedHelpers

    def initialize(*)
      super
      lock
    end

    def setup(*groups)
      # Has to happen first
      clean_load_path

      specs = groups.any? ? @definition.specs_for(groups) : requested_specs

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
      self
    end

    def require(*groups)
      groups.map! { |g| g.to_sym }
      groups = [:default] if groups.empty?

      @definition.dependencies.each do |dep|
        # Skip the dependency if it is not in any of the requested
        # groups
        next unless (dep.groups & groups).any?

        begin
          # Loop through all the specified autorequires for the
          # dependency. If there are none, use the dependency's name
          # as the autorequire.
          Array(dep.autorequire || dep.name).each do |file|
            Kernel.require file
          end
        rescue LoadError
          # Only let a LoadError through if the autorequire was explicitly
          # specified by the user.
          raise if dep.autorequire
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

  private

    def cache_path
      root.join("vendor/cache")
    end

  end
end
