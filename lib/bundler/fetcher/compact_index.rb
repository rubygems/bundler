require "bundler/fetcher/base"

module Bundler
  class Fetcher
    class CompactIndex < Base
      require "bundler/vendor/compact_index_client/lib/compact_index_client"

      def specs(gem_names)
        specs_for_names(gem_names)
      rescue NetworkDownError => e
        raise HTTPError, e.message
      rescue AuthenticationRequiredError
        raise # We got a 401 from the server. Just fail.
      rescue HTTPError => e
        Bundler.ui.trace(e)
        nil
      end

      def specs_for_names(gem_names)
        gem_info = []
        complete_gems = []
        remaining_gems = gem_names.dup

        until remaining_gems.empty?
          Bundler.ui.debug "Looking up gems #{remaining_gems.inspect}"

          deps = compact_index_client.dependencies(remaining_gems)
          next_gems = deps.map {|d| d[3].map(&:first).flatten(1) }.flatten(1).uniq
          deps.each {|dep| gem_info << dep }
          complete_gems.push(*deps.map(&:first)).uniq!
          remaining_gems = next_gems - complete_gems
        end

        gem_info
      end

      def fetch_spec(spec)
        spec -= [nil, "ruby", ""]
        contents = compact_index_client.spec(*spec)
        return nil if contents.nil?
        contents.unshift(spec.first)
        contents[3].map! {|d| Gem::Dependency.new(*d) }
        EndpointSpecification.new(*contents)
      end

      def available?
        # Read info file checksums out of /versions, so we can know if gems are up to date
        fetch_uri.scheme != "file" && compact_index_client.update_and_parse_checksums!
      rescue NetworkDownError => e
        raise HTTPError, e.message
      rescue AuthenticationRequiredError
        # We got a 401 from the server. Just fail.
        raise
      rescue HTTPError
        false
      end

      def api_fetcher?
        true
      end

    private

      def compact_index_client
        @compact_index_client ||= begin
          compact_fetcher = lambda do |path, headers|
            downloader.fetch(fetch_uri + path, headers)
          end

          SharedHelpers.filesystem_access(cache_path) do
            CompactIndexClient.new(cache_path, compact_fetcher)
          end
        end
      end

      def cache_path
        uri_parts = [display_uri.host, display_uri.port, display_uri.path].compact.join(".")
        uri_digest = Digest::MD5.hexdigest(uri_parts)

        cache_path = [display_uri.host, display_uri.port, uri_digest[0..5]].compact.join(".")
        Bundler.user_cache.join("compact_index", cache_path)
      end
    end
  end
end
