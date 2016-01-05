require "bundler/fetcher/base"
require "bundler/worker"

module Bundler
  class Fetcher
    class CompactIndex < Base
      require "bundler/vendor/compact_index_client/lib/compact_index_client"

      def self.compact_index_request(method_name)
        method = instance_method(method_name)
        define_method(method_name) do |*args, &blk|
          begin
            method.bind(self).call(*args, &blk)
          rescue NetworkDownError, CompactIndexClient::Updater::MisMatchedChecksumError => e
            raise HTTPError, e.message
          rescue AuthenticationRequiredError
            # We got a 401 from the server. Just fail.
            raise
          rescue HTTPError => e
            Bundler.ui.trace(e)
            nil
          end
        end
      end

      def specs(gem_names)
        specs_for_names(gem_names)
      end
      compact_index_request :specs

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
      compact_index_request :fetch_spec

      def available?
        # Read info file checksums out of /versions, so we can know if gems are up to date
        fetch_uri.scheme != "file" && compact_index_client.update_and_parse_checksums!
      end
      compact_index_request :available?

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
          end.tap do |client|
            client.in_parallel = lambda do |inputs, &blk|
              worker = Bundler::Worker.new(25, blk)
              inputs.each {|input| worker.enq(input) }
              inputs.map { worker.deq }
            end
          end
        end
      end

      def cache_path
        Bundler.user_cache.join("compact_index", remote.cache_slug)
      end
    end
  end
end
