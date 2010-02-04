require "digest/md5"

module Bundler
  class Runtime < Environment
    def setup(*groups)
      # Has to happen first
      cripple_rubygems

      # Activate the specs
      specs_for(*groups).each do |spec|
        Gem.loaded_specs[spec.name] = spec
        $LOAD_PATH.unshift(*spec.load_paths)
      end
      self
    end

    def require(*groups)
      groups = [:default] if groups.empty?
      autorequires = autorequires_for_groups(*groups)
      groups.each do |group|
        (autorequires[group] || []).each do |path|
          Kernel.require(path)
        end
      end
    end

    def dependencies
      @definition.actual_dependencies
    end

    def lock
      FileUtils.mkdir_p("#{root}/.bundle")
      write_yml_lock
      write_rb_lock
      Bundler.ui.info("The bundle is now locked. Use `bundle show` to list the gems in the environment.")
    end

    def unlock
      unless locked?
        Bundler.ui.info("The bundle is not currently locked.")
        return
      end

      FileUtils.rm_f("#{root}/.bundle/environment.rb")
      FileUtils.rm_f("#{root}/Gemfile.lock")
      Bundler.ui.info("The bundle is now unlocked. The dependencies may be changed.")
    end

    def lock
      Bundler.ui.info("The bundle is already locked, relocking.") if locked?
      sources.each { |s| s.lock if s.respond_to?(:lock) }
      FileUtils.mkdir_p("#{root}/.bundle")
      write_yml_lock
      write_rb_lock
      Bundler.ui.info("The bundle is now locked. Use `bundle show` to list the gems in the environment.")
    end

    def locked?
      File.exist?("#{root}/Gemfile.lock")
    end

    def dependencies_for(*groups)
      if groups.empty?
        dependencies
      else
        dependencies.select { |d| (groups & d.groups).any? }
      end
    end

    def specs_for(*groups)
      if groups.empty?
        specs
      else
        Resolver.resolve(dependencies_for(*groups), index)
      end
    end

    def specs
      @specs ||= begin
        source_requirements = {}
        dependencies.each do |dep|
          next unless dep.source && dep.source.respond_to?(:local_specs)
          source_requirements[dep.name] = dep.source.local_specs
        end

        Resolver.resolve(@definition.actual_dependencies, index, source_requirements)
      end
    end

    alias gems specs

    def index
      @definition.local_index
    end

    def pack
      pack_path = "#{root}/vendor/cache/"
      FileUtils.mkdir_p(pack_path)

      Bundler.ui.info "Copying .gem files into vendor/cache"
      specs.each do |spec|
        next unless spec.source.is_a?(Source::SystemGems) || spec.source.is_a?(Source::Rubygems)
        possibilities = Gem.path.map { |p| "#{p}/cache/#{spec.full_name}.gem" }
        cached_path = possibilities.find { |p| File.exist? p }
        Bundler.ui.info "  * #{File.basename(cached_path)}"
        next if File.expand_path(File.dirname(cached_path)) == File.expand_path(pack_path)
        FileUtils.cp(cached_path, pack_path)
      end
    end

  private

    def sources
      @definition.sources
    end

    def load_paths
      specs.map { |s| s.load_paths }.flatten
    end

    def cripple_rubygems
      # handle 1.9 where system gems are always on the load path
      if defined?(::Gem)
        me = File.expand_path("../../", __FILE__)
        $LOAD_PATH.reject! do |p|
          p != File.dirname(__FILE__) &&
            Gem.path.any? { |gp| p.include?(gp) }
        end
        $LOAD_PATH.unshift me
        $LOAD_PATH.uniq!
      end

      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias rubygems_require require
          alias require gem_original_require
        end

        undef gem
        def gem(*)
          # Silently ignore calls to gem
        end
      end
    end

    def write_rb_lock
      template = File.read(File.expand_path("../templates/environment.erb", __FILE__))
      erb = ERB.new(template, nil, '-')
      File.open("#{root}/.bundle/environment.rb", 'w') do |f|
        f.puts erb.result(binding)
      end
    end

    def write_yml_lock
      yml = details.to_yaml
      File.open("#{root}/Gemfile.lock", 'w') do |f|
        f.puts yml
      end
    end

    def details
      details = {}
      details["hash"] = Digest::SHA1.hexdigest(File.read("#{root}/Gemfile"))
      details["sources"] = sources.map { |s| { s.class.name.split("::").last => s.options} }

      details["specs"] = specs.map do |s|
        options = {"version" => s.version.to_s}
        options["source"] = sources.index(s.source) if sources.include?(s.source)
        { s.name => options }
      end

      details["dependencies"] = @definition.dependencies.map { |d| {d.name => d.version_requirements.to_s} }
      details
    end

    def autorequires_for_groups(*groups)
      autorequires = Hash.new { |h,k| h[k] = [] }
      @definition.dependencies.each do |dep|
        dep.groups.each do |group|
          autorequires[group].concat dep.autorequire
        end
      end

      if groups.empty?
        autorequires
      else
        groups.inject({}) { |h,g| h[g] = autorequires[g]; h }
      end
    end
  end
end
