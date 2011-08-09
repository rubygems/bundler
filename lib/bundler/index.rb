module Bundler
  class Index
    include Enumerable

    def self.build
      i = new
      yield i
      i
    end

    attr_reader :specs
    protected   :specs

    def initialize
      @cache = {}
      @specs = Hash.new { |h,k| h[k] = [] }
    end

    def initialize_copy(o)
      super
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

    def search(query)
      case query
      when Gem::Specification, RemoteSpecification, LazySpecification then search_by_spec(query)
      when String then @specs[query]
      else search_by_dependency(query)
      end
    end

    def search_for_all_platforms(dependency, base = [])
      specs = @specs[dependency.name] + base

      wants_prerelease = dependency.requirement.prerelease?
      only_prerelease  = specs.all? {|spec| spec.version.prerelease? }
      found = specs.select { |spec| dependency.matches_spec?(spec) }

      unless wants_prerelease || only_prerelease
        found.reject! { |spec| spec.version.prerelease? }
      end

      found.sort_by {|s| [s.version, s.platform.to_s == 'ruby' ? "\0" : s.platform.to_s] }
    end

    def sources
      @specs.values.map do |specs|
        specs.map{|s| s.source.class }
      end.flatten.uniq
    end

    alias [] search

    def <<(spec)
      arr = @specs[spec.name]

      arr.delete_if do |s|
        same_version?(s.version, spec.version) && s.platform == spec.platform
      end

      arr << spec
      spec
    end

    def each(&blk)
      @specs.values.each do |specs|
        specs.each(&blk)
      end
    end

    def use(other, override_dupes = false)
      return unless other
      other.each do |s|
        if (dupes = search_by_spec(s)) && dupes.any?
          next unless override_dupes
          @specs[s.name] -= dupes
        end
        @specs[s.name] << s
      end
      self
    end

    def ==(o)
      all? do |s|
        s2 = o[s].first and (s.dependencies & s2.dependencies).empty?
      end
    end

  private

    def search_by_spec(spec)
      @specs[spec.name].select do |s|
        same_version?(s.version, spec.version) && Gem::Platform.new(s.platform) == Gem::Platform.new(spec.platform)
      end
    end

    if RUBY_VERSION < '1.9'
      def same_version?(a, b)
        regex = /^(.*?)(?:\.0)*$/
        a.to_s[regex, 1] == b.to_s[regex, 1]
      end
    else
      def same_version?(a, b)
        a == b
      end
    end

    def spec_satisfies_dependency?(spec, dep)
      return false unless dep.name === spec.name
      dep.requirement.satisfied_by?(spec.version)
    end

    def search_by_dependency(dependency)
      @cache[dependency.hash] ||= begin
        specs = @specs[dependency.name]
        found = specs.select { |spec| dependency.matches_spec?(spec) && Gem::Platform.match(spec.platform) }

        wants_prerelease = dependency.requirement.prerelease?
        only_prerelease  = specs.all? {|spec| spec.version.prerelease? }
        unless wants_prerelease || only_prerelease
          found.reject! { |spec| spec.version.prerelease? }
        end

        found.sort_by {|s| [s.version, s.platform.to_s == 'ruby' ? "\0" : s.platform.to_s] }
      end
    end
  end
end
