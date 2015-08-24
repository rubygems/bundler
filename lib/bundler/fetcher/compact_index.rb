require "bundler/fetcher/base"

module Bundler
  class Fetcher
    class CompactIndex < Base
      require "bundler/vendor/compact_index_client/lib/compact_index_client"

      def specs(gem_names)
        @specs ||= specs_for_names(gem_names)
      rescue NetworkDownError => e
        raise HTTPError, e.message
      rescue AuthenticationRequiredError
        raise # We got a 401 from the server. Just fail.
      rescue HTTPError => e
        Bundler.ui.trace(e)
        nil
      end

      def specs_for_names(gem_names)
        gemspecs = []
        complete_gems = []
        remaining_gems = gem_names.dup

        # Read info file checksums out of versions to allow request-skipping
        compact_index_client.parse_checksums!

        until remaining_gems.empty?
          Bundler.ui.debug "Looking up gems #{remaining_gems.inspect}"

          deps = compact_index_client.dependencies(remaining_gems)
          next_gems = deps.flat_map {|d| d[3].flat_map(&:first) }.uniq

          deps.each do |contents|
            contents[1] = Gem::Version.new(contents[1])
            contents[3].map! {|name, reqs| Gem::Dependency.new(name, reqs) }
            gemspecs << EndpointSpecification.new(*contents)
          end

          complete_gems.push(*deps.map(&:first).uniq)
          remaining_gems = next_gems - complete_gems
        end

        gemspecs
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
        fetch_uri.scheme != "file"
      end

      def api_fetcher?
        true
      end

    private

      def compact_index_client
        @compact_index_client ||= begin
          uri_part = [display_uri.hostname, display_uri.port, Digest::MD5.hexdigest(display_uri.path)].compact.join(".")

          compact_fetcher = lambda do |path, headers|
            downloader.fetch(fetch_uri + path, headers)
          end

          CompactIndexClient.new(Bundler.user_cache + "compact_index" + uri_part, compact_fetcher)
        end
      end
    end
  end
end
