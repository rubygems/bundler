module Bundler
  class Index
    def self.from_installed_gems
      # TODO: Why can't we memoize this? It is being mutated somewhere
      from_gem_index(Gem::SourceIndex.from_installed_gems)
    end

    def self.from_gem_index(gem_index)
      index = new
      gem_index.each { |name, spec| index << spec }
      index
    end

    def initialize
      @cache = {}
      @specs = Hash.new { |h,k| h[k] = [] }
    end

    def initialize_copy(o)
      super
      @cache = {}
      @specs = @specs.dup
    end

    def search(query)
      case query
      when Gem::Specification, RemoteSpecification then search_by_spec(query)
      when String then @specs[query]
      else search_by_dependency(query)
      end
    end

    alias [] search

    def <<(spec)
      arr = @specs[spec.name]

      arr.delete_if do |s|
        s.version == spec.version && s.platform == spec.platform
      end

      arr << spec
      spec
    end

    def each
      @specs.values.flatten.each do |spec|
        yield spec
      end
    end

    def merge!(other)
      other.each do |spec|
        self << spec
      end
      self
    end

    def merge(other)
      dup.merge!(other)
    end

  private

    def search_by_spec(spec)
      @specs[spec.name].select { |s| s.version == spec.version }
    end

    def search_by_dependency(dependency)
      @cache[dependency.hash] ||= begin
        specs = @specs[dependency.name]

        wants_prerelease = dependency.version_requirements.prerelease?
        only_prerelease  = specs.all? {|spec| spec.version.prerelease? }
        found = specs.select { |spec| dependency =~ spec }

        unless wants_prerelease || only_prerelease
          found.reject! { |spec| spec.version.prerelease? }
        end

        found.sort_by {|s| [s.version, s.platform.to_s == 'ruby' ? "\0" : s.platform.to_s] }
      end
    end

  end
end