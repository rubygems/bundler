module Bundler
  class Fetcher::CompactGemList
    class Updater
      attr_reader :fetcher
      def initialize(fetcher)
        @fetcher = fetcher
      end

      def update(files)
        files.each do |path, remote_path|
          _update(path, remote_path)
        end
      end

      private

      def _update(path, remote_path)
        headers = {}
        if path.file?
          headers['If-None-Match'] = etag_for_file(path)
          headers['Range'] = "bytes=#{path.size}-"
        end
        response = fetcher.downloader.fetch(fetcher.fetch_uri + remote_path, headers)
        return if Net::HTTPNotModified === response
        mode = Net::HTTPPartialContent === response ? "a" : "w"
        path.open(mode) { |f| f << response.body }
        if etag_for_file(path) != response["ETag"]
          path.delete
          _update(path, remote_path)
        end
      end

      def etag_for_file(path)
        Digest::MD5.file(path).hexdigest
      end
    end
  end
end
