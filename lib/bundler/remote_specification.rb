require "uri"
require "rubygems/spec_fetcher"

module Bundler
  # Represents a lazily loaded gem specification, where the full specification
  # is on the source server in rubygems' "quick" index. The proxy object is to
  # be seeded with what we're given from the source's abbreviated index - the
  # full specification will only be fetched when necesary.
  class RemoteSpecification
    attr_reader :name, :version, :platform
    attr_accessor :source

    def initialize(name, version, platform, source_uri)
      @name     = name
      @version  = version
      @platform = platform
      @source_uri = source_uri
    end

    def full_name
      if platform == Gem::Platform::RUBY or platform.nil? then
        "#{@name}-#{@version}"
      else
        "#{@name}-#{@version}-#{platform}"
      end
    end

    # Because Rubyforge cannot be trusted to provide valid specifications
    # once the remote gem is donwloaded, the backend specification will
    # be swapped out.
    def __swap__(spec)
      @specification = spec
    end

  private

    def _remote_specification
      @specification ||= begin
        Gem::SpecFetcher.new.fetch_spec([@name, @version, @platform], URI(@source_uri.to_s))
      end
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