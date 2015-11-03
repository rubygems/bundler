module Bundler
  class Fetcher
    class Base
      attr_reader :downloader
      attr_reader :display_uri
      attr_reader :remote

      def initialize(downloader, remote, display_uri)
        raise "Abstract class" if self.class == Base
        @downloader = downloader
        @remote = remote
        @display_uri = display_uri
      end

      def remote_uri
        @remote.uri
      end

      def fetch_uri
        @fetch_uri ||= begin
          if remote_uri.host == "rubygems.org"
            uri = remote_uri.dup
            uri.host = "bundler.rubygems.org"
            uri
          else
            remote_uri
          end
        end
      end

      def api_available?
        api_fetcher?
      end

      def api_fetcher?
        false
      end
    end
  end
end
