module Bundler
  # Finder behaves like a rubygems source index in that it responds
  # to #search. It also resolves a list of dependencies finding the
  # best possible configuration of gems that satisifes all requirements
  # without causing any gem activation errors.
  class Finder

    # Takes an array of gem sources and fetches the full index of
    # gems from each one. It then combines the indexes together keeping
    # track of the original source so that any resolved gem can be
    # fetched from the correct source.
    #
    # ==== Parameters
    # *sources<String>:: URI pointing to the gem repository
    def initialize(*sources)
      @results = {}
      @index   = Hash.new { |h,k| h[k] = {} }

      sources.each { |source| fetch(source) }
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
    def resolve(*dependencies)
      Bundler.logger.info "Calculating dependencies..."

      resolved = Resolver.resolve(dependencies, self)
      resolved && GemBundle.new(resolved)
    end

    # Fetches the index from the remote source
    #
    # ==== Parameters
    # source<String>:: URI pointing to the gem repository
    #
    # ==== Raises
    # ArgumentError:: If the source is not a valid gem repository
    def fetch(source)
      Bundler.logger.info "Updating source: #{source}"

      deflated = Gem::RemoteFetcher.fetcher.fetch_path("#{source}/Marshal.4.8.Z")
      inflated = Gem.inflate deflated

      append(Marshal.load(inflated), source)
    rescue Gem::RemoteFetcher::FetchError => e
      raise ArgumentError, "#{source} is not a valid source: #{e.message}"
    end

    # Adds a new gem index linked to a gem source to the over all
    # gem index that gets searched.
    #
    # ==== Parameters
    # index<Gem::SourceIndex>:: The index to append to the list
    # source<String>:: The original source
    def append(index, source)
      index.gems.values.each do |spec|
        next unless Gem::Platform.match(spec.platform)
        spec.source = source
        @index[spec.name][spec.version] ||= spec
      end
      self
    end

    # Searches for a gem that matches the dependency
    #
    # ==== Parameters
    # dependency<Gem::Dependency>:: The gem dependency to search for
    #
    # ==== Returns
    # [Gem::Specification]:: A collection of gem specifications
    #   matching the search
    def search(dependency)
      @results[dependency.hash] ||= begin
        possibilities = @index[dependency.name].values
        possibilities.select do |spec|
          dependency =~ spec
        end.sort_by {|s| s.version }
      end
    end
  end
end