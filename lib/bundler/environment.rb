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
        sources.each do |s|
          idx.use s.local_specs if s.respond_to?(:local_specs)
        end

        idx.use Index.system_gems
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
      begin
        env_file = Bundler.default_gemfile.dirname.join(".bundle/environment.rb")
        env_file.dirname.mkpath
        File.open(env_file, 'w') do |f|
          f.puts <<-RB
  require "rubygems"
  require "bundler/setup"
          RB
        end
      rescue Errno::EACCES
        Bundler.ui.warn "Cannot write .bundle/environment.rb file"
      end
    end

    def gemfile_fingerprint
      Digest::SHA1.hexdigest(File.read(Bundler.default_gemfile))
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
      File.open("#{root}/Gemfile.lock", 'w') do |f|
        f.puts details
      end
    end

    def details
      output = ""

      pinned_sources = dependencies.map {|d| d.source }
      all_sources    = @definition.sources.map {|s| s }

      specified_sources = all_sources - pinned_sources

      unless specified_sources.empty?
        output << "sources:\n"

        specified_sources.each do |source|
          output << "  #{source.to_lock}\n"
        end
        output << "\n"
      end

      unless @definition.dependencies.empty?
        output << "dependencies:\n"
        @definition.dependencies.sort_by {|d| d.name }.each do |dependency|
          output << dependency.to_lock
        end
        output << "\n"
      end

      output << "specs:\n"
      specs.sort_by {|s| s.name }.each do |spec|
        output << spec.to_lock
      end

      output
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
