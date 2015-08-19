require "bundler/fetcher/base"

module Bundler
  class Fetcher
    class CompactIndex < Base
      require "bundler/vendor/compact_index_client/lib/compact_index_client"

      def specs(_gem_names)
        @specs ||= compact_index_client.versions.values.flatten(1).map! do |args|
          args = args.fill(nil, args.size..2) << self
          RemoteSpecification.new(*args)
        end
      rescue NetworkDownError => e
        raise HTTPError, e.message
      rescue AuthenticationRequiredError
        # We got a 401 from the server. Just fail.
        raise
      rescue HTTPError
      end

      def fetch_spec(spec)
        spec -= [nil, "ruby", ""]
        return unless contents = compact_index_client.spec(*spec)
        contents.unshift(spec.first)
        contents[3].map! {|d| Gem::Dependency.new(*d) }
        EndpointSpecification.new(*contents)
      end

      def available?
        fetch_uri.scheme != "file" && specs([])
      end

    private

      def compact_index_client
        @compact_index_client ||= begin
          uri_part = [display_uri.hostname, display_uri.port, Digest::MD5.hexdigest(display_uri.path)].compact.join(".")
          fetcher = lambda do |path, headers|
            fetcher.downloader.fetch(fetcher.fetch_uri + path, headers)
          end
          CompactIndexClient.new(Bundler.cache + "compact_index" + uri_part, fetcher)
        end
      end
    end
  end
end
