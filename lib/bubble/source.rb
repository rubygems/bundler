require "rubygems/remote_fetcher"

module Bubble
  module Source
    class Rubygems
      attr_reader :uri

      def initialize(options = {})
        @uri = options[:uri]
        @uri = URI.parse(@uri) unless @uri.is_a?(URI)
        raise ArgumentError, "The source must be an absolute URI" unless @uri.absolute?
      end

      def specs
        @specs ||= fetch_specs
      end

    private

      def fetch_specs
        transform(fetch_main_specs + fetch_prerelease_specs)
      end

      def transform(index)
        gems = Hash.new { |h,k| h[k] = [] }
        index.each do |name, version, platform|
          spec = RemoteSpecification.new(name, version, platform, @uri)
          gems[spec.name] << spec if Gem::Platform.match(spec.platform)
        end
        gems
      end

      def fetch_main_specs
        Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/specs.4.8.gz"))
      rescue Gem::RemoteFetcher::FetchError => e
        raise ArgumentError, "#{to_s} is not a valid source: #{e.message}"
      end

      def fetch_prerelease_specs
        Marshal.load(Gem::RemoteFetcher.fetcher.fetch_path("#{uri}/prerelease_specs.4.8.gz"))
      rescue Gem::RemoteFetcher::FetchError
        Bundler.logger.warn "Source '#{uri}' does not support prerelease gems"
        []
      end
    end
  end
end