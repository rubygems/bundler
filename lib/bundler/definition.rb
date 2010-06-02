require "digest/sha1"

# TODO: In the 0.10 release, there shouldn't be a locked subclass of Definition
module Bundler
  class Definition
    attr_reader :dependencies, :locked_specs, :platforms

    def self.build(gemfile, lockfile, unlock)
      unlock ||= {}
      gemfile = Pathname.new(gemfile).expand_path

      unless gemfile.file?
        raise GemfileNotFound, "#{gemfile} not found"
      end

      # TODO: move this back into DSL
      builder = Dsl.new
      builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
      builder.to_definition(lockfile, unlock)
    end

=begin
    How does the new system work?
    ===
    * Load information from Gemfile and Lockfile
    * Invalidate stale locked specs
      * All specs from stale source are stale
      * All specs that are reachable only through a stale
        dependency are stale.
    * If all fresh dependencies are satisfied by the locked
      specs, then we can try to resolve locally.
=end

    def initialize(lockfile, dependencies, sources, unlock)
      @dependencies, @sources, @unlock = dependencies, sources, unlock

      if lockfile && File.exists?(lockfile)
        locked = LockfileParser.new(File.read(lockfile))
        @platforms      = locked.platforms
        @locked_deps    = locked.dependencies
        @locked_specs   = SpecSet.new(locked.specs)
        @locked_sources = locked.sources
      else
        @platforms      = []
        @locked_deps    = []
        @locked_specs   = SpecSet.new([])
        @locked_sources = []
      end

      converge
    end

    def resolve_remotely!
      raise "Specs already loaded" if @specs
      @specs = resolve_remote_specs
    end

    def specs
      @specs ||= resolve(:local_specs, index)
    end

    def index
      @index ||= Index.build do |idx|
        @sources.each do |s|
          idx.use s.local_specs
        end
      end
    end

    def remote_index
      @remote_index ||= Index.build do |idx|
        @sources.each { |source| idx.use source.specs }
      end
    end

    def no_sources?
      @sources.length == 1 && @sources.first.remotes.empty?
    end

    def groups
      dependencies.map { |d| d.groups }.flatten.uniq
    end

    def to_lock
      out = ""

      sorted_sources.each do |source|
        # Add the source header
        out << source.to_lock
        # Find all specs for this source
        specs.
          select  { |s| s.source == source }.
          sort_by { |s| s.name }.
          each do |spec|
            out << spec.to_lock
        end
        out << "\n"
      end

      out << "PLATFORMS\n"

      # Add the current platform
      platforms = @platforms.dup
      platforms << Gem::Platform.local unless @platforms.any? do |p|
        p == Gem::Platform.local
      end

      platforms.map { |p| p.to_s }.sort.each do |p|
        out << "  #{p}\n"
      end

      out << "\n"
      out << "DEPENDENCIES\n"

      dependencies.
        sort_by { |d| d.name }.
        each do |dep|
          out << dep.to_lock
      end

      out
    end

  private

    def converge
      converge_sources
      converge_dependencies
      converge_locked_specs
    end

    def converge_sources
      @sources = (@locked_sources & @sources) | @sources
      @sources.each do |source|
        source.unlock! if source.respond_to?(:unlock!) && (@unlock[:sources] || []).include?(source.name)
      end
    end

    def converge_dependencies
      (@dependencies + @locked_deps).each do |dep|
        if dep.source && source = @sources.find { |s| dep.source == s }
          dep.source = source
        end
      end
    end

    def converge_locked_specs
      deps = []

      @dependencies.each do |dep|
        if in_locked_deps?(dep) || satisfies_locked_spec?(dep)
          deps << dep
        end
      end

      @locked_specs = @locked_specs.for(deps, @unlock[:gems] || [])

      @locked_specs.each do |s|
        s.source = @sources.find { |source| s.source == source }
      end

      @locked_specs.delete_if do |s|
        s.source.nil? || (@unlock[:sources] || []).include?(s.name)
      end
    end

    def in_locked_deps?(dep)
      @locked_deps.any? do |d|
        dep == d && dep.source == d.source
      end
    end

    def satisfies_locked_spec?(dep)
      @locked_specs.any? { |s| s.satisfies?(dep) }
    end

    def sorted_sources
      @sources.sort_by do |s|
        # Place GEM at the top
        [ s.is_a?(Source::Rubygems) ? 1 : 0, s.to_s ]
      end
    end

    def resolve(type, idx)
      source_requirements = {}
      dependencies.each do |dep|
        next unless dep.source
        source_requirements[dep.name] = dep.source.send(type)
      end

      # Run a resolve against the locally available gems
      specs = Resolver.resolve(dependencies, idx, source_requirements, locked_specs)
      specs.__materialize__ do |spec|
        spec.__materialize__(spec.source.send(type))
      end
      specs
    end

    # TODO: Improve this logic
    def resolve_remote_specs
      locked_specs.for(dependencies) # Will raise on fail
      specs
    rescue #InvalidSpecSet, GemNotFound, PathError
      resolve(:specs, remote_index)
    end
  end
end
