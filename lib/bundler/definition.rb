require "digest/sha1"

module Bundler
  class Definition
    include GemHelpers

    attr_reader :dependencies, :platforms, :sources

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
      @remote = false
      @specs = nil

      if lockfile && File.exists?(lockfile) && unlock != true
        locked = LockfileParser.new(File.read(lockfile))
        @platforms      = locked.platforms
        @locked_deps    = locked.dependencies
        @last_resolve   = SpecSet.new(locked.specs)
        @locked_sources = locked.sources
      else
        @unlock         = {}
        @platforms      = []
        @locked_deps    = []
        @last_resolve   = SpecSet.new([])
        @locked_sources = []
      end

      @unlock[:gems] ||= []
      @unlock[:sources] ||= []

      current_platform = Gem.platforms.map { |p| generic(p) }.compact.last
      @platforms |= [current_platform]

      converge
    end

    def resolve_with_cache!
      raise "Specs already loaded" if @specs
      @sources.each { |s| s.cached! }
      specs
    end

    def resolve_remotely!
      raise "Specs already loaded" if @specs
      @remote = true
      @sources.each { |s| s.remote! }
      specs
    end

    def specs
      @specs ||= begin
        specs = resolve.materialize(requested_dependencies)

        unless specs["bundler"].any?
          bundler = index.search(Gem::Dependency.new('bundler', VERSION)).last
          specs["bundler"] = bundler if bundler
        end

        specs
      end
    end

    def missing_specs
      missing = []
      resolve.materialize(requested_dependencies, missing)
      missing
    end

    def requested_specs
      @requested_specs ||= begin
        groups = self.groups - Bundler.settings.without
        groups.map! { |g| g.to_sym }
        specs_for(groups)
      end
    end

    def current_dependencies
      dependencies.reject { |d| !d.should_include? }
    end

    def specs_for(groups)
      deps = dependencies.select { |d| (d.groups & groups).any? }
      deps.delete_if { |d| !d.should_include? }
      specs.for(expand_dependencies(deps))
    end

    def resolve
      @resolve ||= begin
        if @last_resolve.valid_for?(expanded_dependencies)
          @last_resolve
        else
          source_requirements = {}
          dependencies.each do |dep|
            next unless dep.source
            source_requirements[dep.name] = dep.source.specs
          end

          # Run a resolve against the locally available gems
          @last_resolve.merge Resolver.resolve(expanded_dependencies, index, source_requirements, @last_resolve)
        end
      end
    end

    def index
      @index ||= Index.build do |idx|
        @sources.each do |s|
          idx.use s.specs
        end
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
        resolve.
          select  { |s| s.source == source }.
          sort_by { |s| s.name }.
          each do |spec|
            next if spec.name == 'bundler'
            out << spec.to_lock
        end
        out << "\n"
      end

      out << "PLATFORMS\n"

      platforms.map { |p| p.to_s }.sort.each do |p|
        out << "  #{p}\n"
      end

      out << "\n"
      out << "DEPENDENCIES\n"

      handled = []
      dependencies.
        sort_by { |d| d.name }.
        each do |dep|
          next if handled.include?(dep.name)
          out << dep.to_lock
          handled << dep.name
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
      @sources.map! do |source|
        @locked_sources.find { |s| s == source } || source
      end
      @sources.each do |source|
        source.unlock! if source.respond_to?(:unlock!) && @unlock[:sources].include?(source.name)
      end
    end

    def converge_dependencies
      (@dependencies + @locked_deps).each do |dep|
        if dep.source
          dep.source = @sources.find { |s| dep.source == s }
        end
      end
    end

    # Remove elements from the locked specs that are expired. This will most
    # commonly happen if the Gemfile has changed since the lockfile was last
    # generated
    def converge_locked_specs
      deps = []

      # Build a list of dependencies that are the same in the Gemfile
      # and Gemfile.lock. If the Gemfile modified a dependency, but
      # the gem in the Gemfile.lock still satisfies it, this is fine
      # too.
      @dependencies.each do |dep|
        if in_locked_deps?(dep) || satisfies_locked_spec?(dep)
          deps << dep
        end
      end

      converged = []
      @last_resolve.each do |s|
        s.source = @sources.find { |src| s.source == src }

        # Don't add a spec to the list if its source is expired. For example,
        # if you change a Git gem to Rubygems.
        next if s.source.nil? || @unlock[:sources].include?(s.name)
        # If the spec is from a path source and it doesn't exist anymore
        # then we just unlock it.

        # Path sources have special logic
        if s.source.instance_of?(Source::Path)
          other = s.source.specs[s].first

          # If the spec is no longer in the path source, unlock it. This
          # commonly happens if the version changed in the gemspec
          next unless other
          # If the dependencies of the path source have changed, unlock it
          next unless s.dependencies.sort == other.dependencies.sort
        end

        converged << s
      end

      resolve = SpecSet.new(converged)
      resolve = resolve.for(expand_dependencies(deps, true), @unlock[:gems])
      @last_resolve = resolve
    end

    def in_locked_deps?(dep)
      @locked_deps.any? do |d|
        dep == d && dep.source == d.source
      end
    end

    def satisfies_locked_spec?(dep)
      @last_resolve.any? { |s| s.satisfies?(dep) && (!dep.source || s.source == dep.source) }
    end

    def expanded_dependencies
      @expanded_dependencies ||= expand_dependencies(dependencies, @remote)
    end

    def expand_dependencies(dependencies, remote = false)
      deps = []
      dependencies.each do |dep|
        dep.gem_platforms(@platforms).each do |p|
          deps << DepProxy.new(dep, p) if remote || p == generic(Gem::Platform.local)
        end
      end
      deps
    end

    def sorted_sources
      @sources.sort_by do |s|
        # Place GEM at the top
        [ s.is_a?(Source::Rubygems) ? 1 : 0, s.to_s ]
      end
    end

    def requested_dependencies
      groups = self.groups - Bundler.settings.without
      groups.map! { |g| g.to_sym }
      dependencies.reject { |d| !d.should_include? || (d.groups & groups).empty? }
    end
  end
end
