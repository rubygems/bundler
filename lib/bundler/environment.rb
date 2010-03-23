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
        groups.any? ? specs_for(groups) : []
      end
    end

    def specs
      @specs ||= resolve_locally || resolve_remotely
    end

  private

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
      actual_dependencies.each do |dep|
        next unless dep.source && dep.source.respond_to?(type)
        source_requirements[dep.name] = dep.source.send(type)
      end

      # Run a resolve against the locally available gems
      Resolver.resolve(actual_dependencies, index, source_requirements)
    end

    def resolve_locally
      resolve(:local_specs, index)
    end

    def resolve_remotely
      raise NotImplementedError
    end

    def specs_for(groups)
      deps = dependencies.select { |d| (d.groups & groups).any? }
      # deps.any? ? specs.for(deps) : specs
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
      FileUtils.mkdir_p(rb_lock_file.dirname)
      File.open(rb_lock_file, 'w') do |f|
        f.puts erb.result(binding)
      end
    end

    def rb_lock_file
      root.join(".bundle/environment.rb")
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

    def autorequires_for_groups(*groups)
      groups.map! { |g| g.to_sym }
      autorequires = Hash.new { |h,k| h[k] = [] }

      ordered_deps = []
      specs = groups.any? ? specs_for(groups) : requested_specs
      specs.each do |g|
        dep = @definition.dependencies.find{|d| d.name == g.name }
        ordered_deps << dep if dep && !ordered_deps.include?(dep)
      end

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
