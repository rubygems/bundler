require 'bundler/fetcher/base'
require 'bundler/fetcher/compact_gem_list'

module Bundler
  class Fetcher
    class CompactIndex < Base
      def specs(_gem_names)
        compact_gem_list.versions.map do |*args|
          RemoteSpecification.new(*args, self)
        end
      end

      def fetch_spec(spec)
        spec = spec - [nil, 'ruby', '']
        compact_gem_list.spec(*spec)
      end

      private

      def compact_gem_list
        @compact_gem_list ||= begin
          uri_part = [display_uri.hostname, display_uri.port, Digest::MD5.hexdigest(display_uri.path)].compact.join('.')
          CompactGemList.new(self, Bundler.cache + 'compact_index' + uri_part)
        end
      end
    end
  end
end
