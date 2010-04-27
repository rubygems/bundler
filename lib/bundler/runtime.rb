require "digest/sha1"

module Bundler
  class Runtime < Environment
    include SharedHelpers

    def initialize(*)
      super
      write_rb_lock if locked? && !defined?(Bundler::ENV_LOADED)
    end

    def setup(*groups)
      # Has to happen first
      clean_load_path

      specs = groups.any? ? specs_for(groups) : requested_specs

      cripple_rubygems(specs)
      replace_rubygems_paths

      # Activate the specs
      specs.each do |spec|
        unless spec.loaded_from
          raise GemNotFound, "#{spec.full_name} is cached, but not installed."
        end

        Gem.loaded_specs[spec.name] = spec
        spec.load_paths.each do |path|
          $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
        end
      end
      self
    end

    def require(*groups)
      groups.map! { |g| g.to_sym }
      groups = [:default] if groups.empty?
      autorequires = autorequires_for_groups(*groups)

      groups.each do |group|
        (autorequires[group] || [[]]).each do |path, explicit|
          if explicit
            Kernel.require(path)
          else
            begin
              Kernel.require(path)
            rescue LoadError
            end
          end
        end
      end
    end

    def dependencies
      @definition.dependencies
    end

    def actual_dependencies
      @definition.actual_dependencies
    end

    def lock
      sources.each { |s| s.lock if s.respond_to?(:lock) }
      FileUtils.mkdir_p("#{root}/.bundle")
      write_yml_lock
      write_rb_lock
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

      Bundler.ui.info "Copying .gem files into vendor/cache"
      specs.each do |spec|
        next unless spec.source.is_a?(Source::SystemGems) || spec.source.is_a?(Source::Rubygems)
        possibilities = Gem.path.map { |p| "#{p.to_s}/cache/#{spec.full_name}.gem" }
        cached_path = possibilities.find { |p| File.exist? p }
        raise GemNotFound, "Missing gem file '#{spec.full_name}.gem'." unless cached_path
        Bundler.ui.info "  * #{File.basename(cached_path)}"
        next if File.expand_path(File.dirname(cached_path)) == File.expand_path(cache_path)
        FileUtils.cp(cached_path, cache_path)
      end
    end

    def prune_cache
      FileUtils.mkdir_p(cache_path)
      Bundler.ui.info "Removing outdated .gem files from vendor/cache"
      Pathname.glob(cache_path.join("*.gem").to_s).each do |gem_path|
        cached_spec = Gem::Format.from_file_by_path(gem_path.to_s).spec
        next unless Gem::Platform.match(cached_spec.platform)
        unless specs.any?{|s| s.full_name == cached_spec.full_name }
          Bundler.ui.info "  * #{File.basename(gem_path.to_s)}"
          gem_path.rmtree
        end
      end
    end

    private

    def load_paths
      specs.map { |s| s.load_paths }.flatten
    end

    def cache_path
      root.join("vendor/cache")
    end

    def write_yml_lock
      yml = details.to_yaml
      File.open("#{root}/Gemfile.lock", 'w') do |f|
        f.puts yml
      end
    end

    def details
      details = {}
      details["hash"] = gemfile_fingerprint
      details["sources"] = sources.map { |s| { s.class.name.split("::").last => s.options} }

      details["specs"] = specs.map do |s|
        options = {"version" => s.version.to_s}
        options["source"] = sources.index(s.source) if sources.include?(s.source)
        { s.name => options }
      end

      details["dependencies"] = @definition.dependencies.inject({}) do |h,d|
        info = {"version" => d.requirement.to_s, "group" => d.groups}
        info.merge!("require" => d.autorequire) if d.autorequire
        h.merge(d.name => info)
      end
      details
    end

    def replace_rubygems_paths
      Gem.instance_eval do
        def path
          [Bundler.bundle_path.to_s]
        end

        def source_index
          @source_index ||= Gem::SourceIndex.from_installed_gems
        end
      end
    end

  end
end
