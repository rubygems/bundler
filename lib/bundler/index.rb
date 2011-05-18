module Bundler
  class Index
    include Enumerable

    def self.build
      i = new
      yield i
      i
    end

    attr_reader :specs, :sources
    protected   :specs

    def initialize
      @sources = []
      @cache = {}
      @specs = Hash.new { |h,k| h[k] = [] }
    end

    def initialize_copy(o)
      super
      @sources = @sources.dup
      @cache = {}
      @specs = Hash.new { |h,k| h[k] = [] }

      o.specs.each do |name, array|
        @specs[name] = array.dup
      end
    end

    def empty?
      each { return false }
      true
    end

    # Search this index's specs, and any source indexes that this index knows
    # about, returning all of the results.
    def search(query)
      results = local_search(query)
      @sources.each do |source|
        results << source.search(query)
      end
      results
    end

    def local_search(query)
      case query
      when Gem::Specification, RemoteSpecification, LazySpecification then search_by_spec(query)
      when String then specs_by_name(query)
      when Gem::Dependency then search_by_dependency(query)
      else
        raise "You can't search for a #{query.inspect}."
      end
    end

    def specs_by_name(name)
      @specs[name]
    end

    def search_by_dependency(dependency, base = nil)
      @cache[dependency.hash] ||= begin
        specs = specs_by_name(dependency.name) + (base || [])
        found = specs.select do |spec|
          if base # allow all platforms when searching from a lockfile
            dependency.matches_spec?(spec)
          else
            dependency.matches_spec?(spec) && Gem::Platform.match(spec.platform)
          end
        end

        wants_prerelease = dependency.requirement.prerelease?
        only_prerelease  = specs.all? {|spec| spec.version.prerelease? }

        unless wants_prerelease || only_prerelease
          found.reject! { |spec| spec.version.prerelease? }
        end

        found.sort_by {|s| [s.version, s.platform.to_s == 'ruby' ? "\0" : s.platform.to_s] }
      end
    end

    def source_types
      sources.map{|s| s.class }.uniq
    end

    alias [] search

    def <<(spec)
      arr = specs_by_name(spec.name)

      arr.delete_if do |s|
        same_version?(s.version, spec.version) && s.platform == spec.platform
      end

      arr << spec
      spec
    end

    def each(&blk)
      specs.values.each do |specs|
        specs.each(&blk)
      end
    end

    def use(other)
      return unless other
      other.each do |s|
        next if search_by_spec(s).any?
        @specs[s.name] << s
      end
      self
    end

    def ==(o)
      all? do |s|
        s2 = o[s].first and (s.dependencies & s2.dependencies).empty?
      end
    end

    def add_source(source)
      raise ArgumentError, "Source must be an index, not #{source.class}" unless source.is_a?(Index)
      @sources << source
    end

  private

    def search_by_spec(spec)
      specs_by_name(spec.name).select do |s|
        same_version?(s.version, spec.version) && Gem::Platform.new(s.platform) == Gem::Platform.new(spec.platform)
      end
    end

    def same_version?(a, b)
      regex = /^(.*?)(?:\.0)*$/

      a.to_s[regex, 1] == b.to_s[regex, 1]
    end

    def spec_satisfies_dependency?(spec, dep)
      return false unless dep.name === spec.name
      dep.requirement.satisfied_by?(spec.version)
    end

  end
end
