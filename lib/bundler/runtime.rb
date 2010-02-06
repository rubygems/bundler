require "digest/sha1"

module Bundler
  class Runtime < Environment
    def setup(*groups)
      # Has to happen first
      clean_load_path

      specs = specs_for(*groups)

      cripple_rubygems(specs)

      # Activate the specs
      specs.each do |spec|
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
      details["hash"] = gemfile_fingerprint
      details["sources"] = sources.map { |s| { s.class.name.split("::").last => s.options} }

      details["specs"] = specs.map do |s|
        options = {"version" => s.version.to_s}
        options["source"] = sources.index(s.source) if sources.include?(s.source)
        { s.name => options }
      end

      details["dependencies"] = @definition.dependencies.map { |d| {d.name => d.version_requirements.to_s} }
      details
    end

    def gemfile_fingerprint
      Digest::SHA1.hexdigest(File.read("#{root}/Gemfile"))
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

    def clean_load_path
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
    end

    def reverse_rubygems_kernel_mixin
      # Disable rubygems' gem activation system
      ::Kernel.class_eval do
        if private_method_defined?(:gem_original_require)
          alias rubygems_require require
          alias require gem_original_require
        end

        undef gem
      end
    end

    def cripple_rubygems(specs)
      reverse_rubygems_kernel_mixin

      executables = specs.map { |s| s.executables }.flatten

      ::Kernel.send(:define_method, :gem) do |dep, *reqs|
        if executables.include? File.basename(caller.first.split(':').first)
          return
        end
        opts = reqs.last.is_a?(Hash) ? reqs.pop : {}

        unless dep.respond_to?(:name) && dep.respond_to?(:version_requirements)
          dep = Gem::Dependency.new(dep, reqs)
        end

        spec = specs.find  { |s| s.name == dep.name }

        if spec.nil?
          e = Gem::LoadError.new "#{dep} is not part of the bundle. Add it to Gemfile."
          e.name = dep.name
          e.version_requirement = dep.version_requirements
          raise e
        elsif dep !~ spec
          e = Gem::LoadError.new "can't activate #{dep}, already activated #{spec.full_name}. " \
                                 "Make sure all dependencies are added to Gemfile."
          e.name = dep.name
          e.version_requirement = dep.version_requirements
          raise e
        end

        true
      end

      # === Following hacks are to improve on the generated bin wrappers ===

      # Yeah, talk about a hack
      source_index_class = (class << Gem::SourceIndex ; self ; end)
      source_index_class.send(:define_method, :from_gems_in) do |*args|
        source_index = Gem::SourceIndex.new
        source_index.add_specs *specs
        source_index
      end

      # OMG more hacks
      gem_class = (class << Gem ; self ; end)
      gem_class.send(:define_method, :bin_path) do |name, *args|
        exec_name, *reqs = args

        spec = nil

        if exec_name
          spec = specs.find { |s| s.executables.include?(exec_name) }
          spec or raise Gem::Exception, "can't find executable #{exec_name}"
        else
          spec = specs.find  { |s| s.name == name }
          exec_name = spec.default_executable or raise Gem::Exception, "no default executable for #{spec.full_name}"
        end

        File.join(spec.full_gem_path, spec.bindir, exec_name)
      end
    end
  end
end
