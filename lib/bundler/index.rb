module Bundler
  class Index
    def self.build
      i = new
      yield i
      i
    end

    def self.installed_gems
      Source::SystemGems.new.specs
    end

    def self.cached_gems
      build do |idx|
        idx.use application_cached_gems
        idx.use system_cached_gems
      end
    end

    def self.application_cached_gems
      path = "#{Bundler.root}/vendor/cache"
      if File.directory?(path)
        from_cached_specs(path)
      end
    end

    def self.system_cached_gems
      from_cached_specs("#{Bundler.bundle_path}/cache")
    end

    def self.from_cached_specs(path)
      Source::GemCache.new("path" => path).specs
    end

    def initialize
      @cache = {}
      @specs = Hash.new { |h,k| h[k] = [] }
    end

    def initialize_copy(o)
      super
      @cache = {}
      @specs = Hash.new { |h,k| h[k] = [] }
      merge!(o)
    end

    def empty?
      each { return false }
      true
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

    def each(&blk)
      @specs.values.each do |specs|
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

  private

    def search_by_spec(spec)
      @specs[spec.name].select { |s| s.version == spec.version && s.platform == spec.platform }
    end

    def search_by_dependency(dependency)
      @cache[dependency.hash] ||= begin
        specs = @specs[dependency.name]

        wants_prerelease = dependency.requirement.prerelease?
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