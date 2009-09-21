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

    private

    def _remote_uri
      "#{@source_uri}/quick/Marshal.4.8/#{@name}-#{@version}.gemspec.rz"
    end

    def _remote_specification
      @specification ||= begin
        deflated = Gem::RemoteFetcher.fetcher.fetch_path(_remote_uri)
        inflated = Gem.inflate(deflated)
        Marshal.load(inflated)
      end
    end

    def method_missing(method, *args, &blk)
      _remote_specification.send(method, *args, &blk)
    end
  end
end