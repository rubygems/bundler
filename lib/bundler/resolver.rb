# frozen_string_literal: true
module Bundler
  class Resolver
    require "bundler/vendored_molinillo"

    class Molinillo::VersionConflict
      def printable_dep(dep)
        if dep.is_a?(Bundler::Dependency)
          DepProxy.new(dep, dep.platforms.join(", ")).to_s.strip
        else
          dep.to_s
        end
      end

      def message
        conflicts.sort.reduce(String.new) do |o, (name, conflict)|
          o << %(Bundler could not find compatible versions for gem "#{name}":\n)
          if conflict.locked_requirement
            o << %(  In snapshot (#{Bundler.default_lockfile.basename}):\n)
            o << %(    #{printable_dep(conflict.locked_requirement)}\n)
            o << %(\n)
          end
          o << %(  In Gemfile:\n)
          o << conflict.requirement_trees.sort_by {|t| t.reverse.map(&:name) }.map do |tree|
            t = String.new
            depth = 2
            tree.each do |req|
              t << "  " * depth << req.to_s
              unless tree.last == req
                if spec = conflict.activated_by_name[req.name]
                  t << %( was resolved to #{spec.version}, which)
                end
                t << %( depends on)
              end
              t << %(\n)
              depth += 1
            end
            t
          end.join("\n")

          if name == "bundler"
            o << %(\n  Current Bundler version:\n    bundler (#{Bundler::VERSION}))
            other_bundler_required = !conflict.requirement.requirement.satisfied_by?(Gem::Version.new Bundler::VERSION)
          end

          if name == "bundler" && other_bundler_required
            o << "\n"
            o << "This Gemfile requires a different version of Bundler.\n"
            o << "Perhaps you need to update Bundler by running `gem install bundler`?\n"
          end
          if conflict.locked_requirement
            o << "\n"
            o << %(Running `bundle update` will rebuild your snapshot from scratch, using only\n)
            o << %(the gems in your Gemfile, which may resolve the conflict.\n)
          elsif !conflict.existing
            o << "\n"
            if conflict.requirement_trees.first.size > 1
              o << "Could not find gem '#{conflict.requirement}', which is required by "
              o << "gem '#{conflict.requirement_trees.first[-2]}', in any of the sources."
            else
              o << "Could not find gem '#{conflict.requirement}' in any of the sources\n"
            end
          end
          o
        end
      end
    end

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
          @specs[p] = reverse.find {|s| s.match_platform(p) }
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
          next unless s = @specs[p]
          platform = generic(Gem::Platform.new(s.platform))
          next if specs[platform]

          lazy_spec = LazySpecification.new(name, version, platform, source)
          lazy_spec.dependencies.replace s.dependencies
          specs[platform] = lazy_spec
        end
        specs.values
      end

      def activate_platform!(platform)
        @activated << platform if !@activated.include?(platform) && for?(platform, nil)
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

      def for?(platform, required_ruby_version)
        if spec = @specs[platform]
          if required_ruby_version && spec.respond_to?(:required_ruby_version) && spec_required_ruby_version = spec.required_ruby_version
            spec_required_ruby_version.satisfied_by?(required_ruby_version.to_gem_version_with_patchlevel)
          else
            true
          end
        end
      end

      def to_s
        "#{name} (#{version})"
      end

      def dependencies_for_activated_platforms
        @activated.map {|p| __dependencies[p] }.flatten
      end

      def platforms_for_dependency_named(dependency)
        __dependencies.select {|_, deps| deps.map(&:name).include? dependency }.keys
      end

    private

      def __dependencies
        @dependencies ||= begin
          dependencies = {}
          ALL.each do |p|
            next unless spec = @specs[p]
            dependencies[p] = []
            spec.dependencies.each do |dep|
              next if dep.type == :development
              dependencies[p] << DepProxy.new(dep, p)
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
    def self.resolve(requirements, index, source_requirements = {}, base = [], ruby_version = nil, gem_version_promoter = GemVersionPromoter.new)
      base = SpecSet.new(base) unless base.is_a?(SpecSet)
      resolver = new(index, source_requirements, base, ruby_version, gem_version_promoter)
      result = resolver.start(requirements)
      SpecSet.new(result)
    end

    def initialize(index, source_requirements, base, ruby_version, gem_version_promoter)
      @index = index
      @source_requirements = source_requirements
      @base = base
      @resolver = Molinillo::Resolver.new(self, self)
      @search_for = {}
      @base_dg = Molinillo::DependencyGraph.new
      @base.each {|ls| @base_dg.add_vertex(ls.name, Dependency.new(ls.name, ls.version), true) }
      @ruby_version = ruby_version
      @gem_version_promoter = gem_version_promoter
    end

    def start(requirements)
      verify_gemfile_dependencies_are_found!(requirements)
      dg = @resolver.resolve(requirements, @base_dg)
      dg.map(&:payload).map(&:to_specs).flatten
    rescue Molinillo::VersionConflict => e
      raise VersionConflict.new(e.conflicts.keys.uniq, e.message)
    rescue Molinillo::CircularDependencyError => e
      names = e.dependencies.sort_by(&:name).map {|d| "gem '#{d.name}'" }
      raise CyclicDependencyError, "Your bundle requires gems that depend" \
        " on each other, creating an infinite loop. Please remove" \
        " #{names.count > 1 ? "either " : ""}#{names.join(" or ")}" \
        " and try again."
    end

    include Molinillo::UI

    # Conveys debug information to the user.
    #
    # @param [Integer] depth the current depth of the resolution process.
    # @return [void]
    def debug(depth = 0)
      return unless debug?
      debug_info = yield
      debug_info = debug_info.inspect unless debug_info.is_a?(String)
      STDERR.puts debug_info.split("\n").map {|s| "  " * depth + s }
    end

    def debug?
      return @debug_mode if defined?(@debug_mode)
      @debug_mode = ENV["DEBUG_RESOLVER"] || ENV["DEBUG_RESOLVER_TREE"]
    end

    def before_resolution
      Bundler.ui.info "Resolving dependencies...", false
    end

    def after_resolution
      Bundler.ui.info ""
    end

    def indicate_progress
      Bundler.ui.info ".", false
    end

    include Molinillo::SpecificationProvider

    def dependencies_for(specification)
      specification.dependencies_for_activated_platforms
    end

    def search_for(dependency)
      platform = dependency.__platform
      dependency = dependency.dep unless dependency.is_a? Gem::Dependency
      search = @search_for[dependency] ||= begin
        index = index_for(dependency)
        results = index.search(dependency, @base[dependency.name])
        if vertex = @base_dg.vertex_named(dependency.name)
          locked_requirement = vertex.payload.requirement
        end
        if results.any?
          nested = []
          results.each do |spec|
            version, specs = nested.last
            if version == spec.version
              specs << spec
            else
              nested << [spec.version, [spec]]
            end
          end
          nested.reduce([]) do |groups, (version, specs)|
            next groups if locked_requirement && !locked_requirement.satisfied_by?(version)
            groups << SpecGroup.new(specs)
          end
        else
          []
        end
      end
      platform_results = search.select {|sg| sg.for?(platform, @ruby_version) }.each {|sg| sg.activate_platform!(platform) }
      return platform_results if @gem_version_promoter.level == :major # default behavior
      # MODO: put this inside the cache
      @gem_version_promoter.sort_versions(dependency, platform_results)
    end

    def index_for(dependency)
      @source_requirements[dependency.name] || @index
    end

    def name_for(dependency)
      dependency.name
    end

    def name_for_explicit_dependency_source
      Bundler.default_gemfile.basename.to_s
    rescue
      "Gemfile"
    end

    def name_for_locking_dependency_source
      Bundler.default_lockfile.basename.to_s
    rescue
      "Gemfile.lock"
    end

    def requirement_satisfied_by?(requirement, activated, spec)
      requirement.matches_spec?(spec) || spec.source.is_a?(Source::Gemspec)
    end

    def sort_dependencies(dependencies, activated, conflicts)
      dependencies.sort_by do |dependency|
        name = name_for(dependency)
        [
          activated.vertex_named(name).payload ? 0 : 1,
          amount_constrained(dependency),
          conflicts[name] ? 0 : 1,
          activated.vertex_named(name).payload ? 0 : search_for(dependency).count,
        ]
      end
    end

  private

    def amount_constrained(dependency)
      @amount_constrained ||= {}
      @amount_constrained[dependency.name] ||= begin
        if (base = @base[dependency.name]) && !base.empty?
          dependency.requirement.satisfied_by?(base.first.version) ? 0 : 1
        else
          all = index_for(dependency).search(dependency.name).size
          if all <= 1
            all
          else
            search = search_for(dependency).size
            search - all
          end
        end
      end
    end

    def verify_gemfile_dependencies_are_found!(requirements)
      requirements.each do |requirement|
        next if requirement.name == "bundler"
        next unless search_for(requirement).empty?
        if (base = @base[requirement.name]) && !base.empty?
          version = base.first.version
          message = "You have requested:\n" \
            "  #{requirement.name} #{requirement.requirement}\n\n" \
            "The bundle currently has #{requirement.name} locked at #{version}.\n" \
            "Try running `bundle update #{requirement.name}`\n\n" \
            "If you are updating multiple gems in your Gemfile at once,\n" \
            "try passing them all to `bundle update`"
        elsif requirement.source
          name = requirement.name
          specs = @source_requirements[name][name]
          versions_with_platforms = specs.map {|s| [s.version, s.platform] }
          message = String.new("Could not find gem '#{requirement}' in #{requirement.source}.\n")
          message << if versions_with_platforms.any?
                       "Source contains '#{name}' at: #{formatted_versions_with_platforms(versions_with_platforms)}"
                     else
                       "Source does not contain any versions of '#{requirement}'"
                     end
        else
          message = "Could not find gem '#{requirement}' in any of the gem sources " \
            "listed in your Gemfile or available on this machine."
        end
        raise GemNotFound, message
      end
    end

    def formatted_versions_with_platforms(versions_with_platforms)
      version_platform_strs = versions_with_platforms.map do |vwp|
        version = vwp.first
        platform = vwp.last
        version_platform_str = String.new(version.to_s)
        version_platform_str << " #{platform}" unless platform.nil?
      end
      version_platform_strs.join(", ")
    end
  end
end
