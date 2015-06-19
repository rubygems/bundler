require "uri"
require "rubygems/spec_fetcher"

module Bundler
  # Represents a lazily loaded gem specification, where the full specification
  # is on the source server in rubygems' "quick" index. The proxy object is to
  # be seeded with what we're given from the source's abbreviated index - the
  # full specification will only be fetched when necessary.
  class RemoteSpecification
    include MatchPlatform
    include Comparable

    attr_reader :name, :version, :platform
    attr_accessor :source, :remote

    def initialize(name, version, platform, spec_fetcher)
      @name         = name
      @version      = version
      @platform     = platform
      @spec_fetcher = spec_fetcher
    end

    # Needed before installs, since the arch matters then and quick
    # specs don't bother to include the arch in the platform string
    def fetch_platform
      @platform = _remote_specification.platform
    end

    def full_name
      if platform == Gem::Platform::RUBY or platform.nil? then
        "#{@name}-#{@version}"
      else
        "#{@name}-#{@version}-#{platform}"
      end
    end

    # Compare this specification against another object. Use comparison
    # that is compatible with Gem::Specification if the other object
    # supports it (i.e. is a Bundler or RubyGems object); else fall
    # back to Object comparison.
    def <=>(other)
      if other.respond_to?(:sort_obj)
        sort_obj <=> other.sort_obj
      else
        super
      end
    end

    # Because Rubyforge cannot be trusted to provide valid specifications
    # once the remote gem is downloaded, the backend specification will
    # be swapped out.
    def __swap__(spec)
      @specification = spec
    end

  private

    # Create a delegate used for sorting. This strategy is copied from
    # RubyGems 2.23 and helps ensure that Bundler's stub specifications
    # compare and sort well against RubyGems' own specifications.
    #
    # @see #<=>
    # @see Gem::Specification#sort_obj
    #
    # @return [Array] an object you can use to compare and sort this
    #   specification against others
    def sort_obj
      [@name, @version, @platform == Gem::Platform::RUBY ? -1 : 1]
    end

    def _remote_specification
      @specification ||= @spec_fetcher.fetch_spec([@name, @version, @platform])
    end

    def method_missing(method, *args, &blk)
      if Gem::Specification.new.respond_to?(method)
        _remote_specification.send(method, *args, &blk)
      else
        super
      end
    end
  end
end
