module Bundler
  class Fetcher::CompactGemList
    class Updater
      attr_reader :fetcher
      def initialize(fetcher)
        @fetcher = fetcher
      end

      def update(files)
        files.each do |path, remote_path|
          response = fetcher.downloader.fetch(fetcher.fetch_uri + remote_path)
          path.open("w") { |f| f.write response }
        end
      end
    end
  end
end
