require 'bundler/fetcher/base'
require 'bundler/fetcher/compact_gem_list'

module Bundler
  class Fetcher
    class CompactIndex < Base
      def specs(_gem_names)
        { remote_uri => compact_gem_list.versions }
      end

      private

      def compact_gem_list
        @compact_gem_list ||= begin
          uri_part = [display_uri.hostname, display_uri.port, Digest::MD5.hexdigest(display_uri.path)i].compact.join('.')
          CompactGemList.new(self, Bundler.cache + 'compact_index' + uri_part)
        end
      end
    end
  end
end
