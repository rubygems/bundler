require 'erb'

module Bundler
  class Environment
    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

    def index
      @index ||= Index.build do |idx|
        idx.use runtime_gems
        idx.use Index.cached_gems
      end
    end

    def requested_specs
      @requested_specs ||= begin
        groups = @definition.groups - Bundler.settings.without
        groups.map! { |g| g.to_sym }
        specs_for(groups)
      end
    end

    def specs
      @specs ||= resolve_locally || resolve_remotely
    end

    def dependencies
      @definition.dependencies
    end

    def resolved_dependencies
      @definition.resolved_dependencies
    end

    def lock
      Bundler.ui.info("The bundle is already locked, relocking.") if locked?
      sources.each { |s| s.lock if s.respond_to?(:lock) }
      FileUtils.mkdir_p("#{root}/.bundle")
      write_yml_lock
      write_rb_lock
      Bundler.ui.confirm("The bundle is now locked. Use `bundle show` to list the gems in the environment.")
    end

  private

    def sources
      @definition.sources
    end

    def runtime_gems
      @runtime_gems ||= Index.build do |i|
        sources.each do |s|
          i.use s.local_specs if s.respond_to?(:local_specs)
        end

        i.use Index.installed_gems
      end
    end

    def resolve(type, index)
      source_requirements = {}
      resolved_dependencies.each do |dep|
        next unless dep.source && dep.source.respond_to?(type)
        source_requirements[dep.name] = dep.source.send(type)
      end

      # Run a resolve against the locally available gems
      Resolver.resolve(resolved_dependencies, index, source_requirements)
    end

    def resolve_locally
      resolve(:local_specs, index)
    end

    def resolve_remotely
      raise NotImplementedError
    end

    def specs_for(groups)
      deps = dependencies.select { |d| (d.groups & groups).any? }
      specs.for(deps)
    end

    # ==== Locking

    def locked?
      File.exist?("#{root}/Gemfile.lock")
    end

    def write_rb_lock
      shared_helpers = File.read(File.expand_path("../shared_helpers.rb", __FILE__))
      template = File.read(File.expand_path("../templates/environment.erb", __FILE__))
      erb = ERB.new(template, nil, '-')
      Bundler.env_file.dirname.mkpath
      File.open(Bundler.env_file, 'w') do |f|
        f.puts erb.result(binding)
      end
    end

    def gemfile_fingerprint
      Digest::SHA1.hexdigest(File.read("#{root}/Gemfile"))
    end

    def specs_for_lock_file
      requested_specs.map do |s|
        hash = {
          :name => s.name,
          :load_paths => s.load_paths
        }
        if s.respond_to?(:relative_loaded_from) && s.relative_loaded_from
          hash[:virtual_spec] = s.to_ruby
        end
        hash[:loaded_from] = s.loaded_from.to_s
        hash
      end
    end

    def load_paths
      specs.map { |s| s.load_paths }.flatten
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

      details["dependencies"] = @definition.dependencies.map do |d|
        info = {"version" => d.requirement.to_s, "group" => d.groups, "name" => d.name}
        info.merge!("require" => d.autorequire) if d.autorequire
        info
      end
      details
    end

    def autorequires_for_groups(*groups)
      groups.map! { |g| g.to_sym }
      groups = groups.any? ? groups : (@definition.groups - Bundler.settings.without)
      autorequires = Hash.new { |h,k| h[k] = [] }

      ordered_deps = @definition.dependencies.find_all{|d| (d.groups & groups).any? }

      ordered_deps.each do |dep|
        dep.groups.each do |group|
          # If there is no autorequire, then rescue from
          # autorequiring the gems name
          if dep.autorequire
            dep.autorequire.each do |file|
              autorequires[group] << [file, true]
            end
          else
            autorequires[group] << [dep.name, false]
          end
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
