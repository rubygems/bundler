module Bundler
  class Fetcher::CompactGemList
    class Updater
      attr_reader :fetcher
      def initialize(fetcher)
        @fetcher = fetcher
      end

      def update(files)
        files.each do |path, remote_path|
          headers = {}
          if path.file?
            headers['If-None-Match'] = Digest::MD5.file(path).hexdigest
            # headers['Range'] = "bytes=#{path.size}-" # uncomment once this is suported
          end
          if response = fetcher.downloader.fetch(fetcher.fetch_uri + remote_path, headers)
            path.open("w") { |f| f.write response }
          end
        end
      end
    end
  end
end
