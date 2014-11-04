require 'set'

# This is the latest iteration of the gem dependency resolving algorithm. As of now,
# it can resolve (as a success or failure) any set of gem dependencies we throw at it
# in a reasonable amount of time. The most iterations I've seen it take is about 150.
# The actual implementation of the algorithm is not as good as it could be yet, but that
# can come later.

module Bundler
  class Resolver

    require 'bundler/vendored_molinillo'

    ALL = Bundler::Dependency::PLATFORM_MAP.values.uniq.freeze

    class SpecGroup < Array
      include GemHelpers

      attr_reader :activated, :required_by

      def initialize(a)
        super
        @required_by  = []
        @activated    = []
        @dependencies = nil
        @specs        = {}

        ALL.each do |p|
          @specs[p] = reverse.find { |s| s.match_platform(p) }
        end
      end

      def initialize_copy(o)
        super
        @required_by = o.required_by.dup
        @activated   = o.activated.dup
      end

      def to_specs
        specs = {}

        @activated.each do |p|
          if s = @specs[p]
            platform = generic(Gem::Platform.new(s.platform))
            next if specs[platform]

            lazy_spec = LazySpecification.new(name, version, platform, source)
            lazy_spec.dependencies.replace s.dependencies
            specs[platform] = lazy_spec
          end
        end
        specs.values
      end

      def activate_platform(platform)
        unless @activated.include?(platform)
          if for?(platform)
            @activated << platform
            return __dependencies[platform] || []
          end
        end
        []
      end

      def name
        @name ||= first.name
      end

      def version
        @version ||= first.version
      end

      def source
        @source ||= first.source
      end

      def for?(platform)
        @specs[platform]
      end

      def to_s
        "#{name} (#{version})"
      end

      def dependencies_for_activated_platforms
        @activated.flat_map { |p| __dependencies[p] }
      end

      def platforms_for_dependency_named(dependency)
        __dependencies.select { |p, deps| deps.map(&:name).include? dependency }.keys
      end

    private

      def __dependencies
        @dependencies ||= begin
          dependencies = {}
          ALL.each do |p|
            if spec = @specs[p]
              dependencies[p] = []
              spec.dependencies.each do |dep|
                next if dep.type == :development
                dependencies[p] << DepProxy.new(dep, p)
              end
            end
          end
          dependencies
        end
      end
    end

    # Figures out the best possible configuration of gems that satisfies
    # the list of passed dependencies and any child dependencies without
    # causing any gem activation errors.
    #
    # ==== Parameters
    # *dependencies<Gem::Dependency>:: The list of dependencies to resolve
    #
    # ==== Returns
    # <GemBundle>,nil:: If the list of dependencies can be resolved, a
    #   collection of gemspecs is returned. Otherwise, nil is returned.
    def self.resolve(requirements, index, source_requirements = {}, base = [])
      Bundler.ui.info "Resolving dependencies...", false
      base = SpecSet.new(base) unless base.is_a?(SpecSet)
      resolver = new(index, source_requirements, base)
      result = resolver.start(requirements)
      Bundler.ui.info "" # new line now that dots are done
      SpecSet.new(result)
    rescue
      Bundler.ui.info "" # new line before the error
      raise
    end


    def initialize(index, source_requirements, base)
      @index = index
      @source_requirements = source_requirements
      @base = base
      @resolver = Molinillo::Resolver.new(self, self)
      @search_for = {}
      @prereleases_cache = Hash.new { |h,k| h[k] = k.prerelease? }
      @base_dg = Molinillo::DependencyGraph.new
      @base.each { |ls| @base_dg.add_root_vertex ls.name, Dependency.new(ls.name, ls.version) }
    end

    def start(requirements)
      dg = @resolver.resolve(requirements, @base_dg)
      dg.map(&:payload).flat_map(&:to_specs)
    rescue Molinillo::VersionConflict => e
      if e.conflicts.values.flat_map(&:requirements).flat_map(&:keys).uniq == %w(Gemfile)
        raise GemNotFound, e.message
      else
        raise VersionConflict.new(e.conflicts.keys.uniq, e.message)
      end
    rescue Molinillo::CircularDependencyError => e
      raise CyclicDependencyError, "Your Gemfile requires gems that depend" \
        " depend on each other, creating an infinite loop. Please remove" \
        " either #{e.dependencies.reverse_each.map { |d| "gem '#{d.name}'"}.join(' or ')}" \
        " and try again."
    end

    def before_resolution
    end
    def after_resolution
    end
    def indicate_progress
    end

    private

    include Molinillo::UI

    include Molinillo::SpecificationProvider

    def dependencies_for(specification)
      specification.dependencies_for_activated_platforms
    end

    def search_for(dependency)
      platform = dependency.__platform
      dependency = dependency.dep unless dependency.is_a? Gem::Dependency
      search = @search_for[dependency.hash] ||= begin
        index = @source_requirements[dependency.name] || @index
        # puts dependency
        # puts index.search(dependency, nil)
        results = index.search(dependency, @base[dependency.name])
        if results.any?
          version = results.first.version
          nested  = [[]]
          results.each do |spec|
            if spec.version != version
              nested << []
              version = spec.version
            end
            nested.last << spec
          end
          nested.map { |a| SpecGroup.new(a) }
        else
          []
        end
      end
      search.select { |sg| sg.for?(platform) }.each { |sg| sg.activate_platform(platform) }
    end

    def name_for(dependency)
      dependency.name
    end

    def name_for_explicit_dependency_source
      'Gemfile'
    end

    def name_for_locking_dependency_source
      'Gemfile.lock'
    end

    def requirement_satisfied_by?(requirement, activated, spec)
      requirement.matches_spec?(spec)
    end

    def sort_dependencies(dependencies, activated, conflicts)
      dependencies.sort_by do |dependency|
        name = name_for(dependency)
        [
          activated.vertex_named(name).payload ? 0 : 1,
          @prereleases_cache[dependency] ? 0 : 1,
          conflicts[name] ? 0 : 1,
          search_for(dependency).count,
        ]
      end
    end

  end
end
