class Bundler::CompactIndexClient
  class Updater
    attr_reader :fetcher
    def initialize(fetcher)
      @fetcher = fetcher
    end

    def update(local_path, remote_path)
      headers = {}
      if local_path.file?
        headers["If-None-Match"] = checksum_for_file(local_path)
        headers["Range"] = "bytes=#{local_path.size}-"
      end
      response = fetcher.call(remote_path, headers)
      return if response.is_a?(Net::HTTPNotModified)
      mode = response.is_a?(Net::HTTPPartialContent) ? "a" : "w"
      local_path.open(mode) {|f| f << response.body }

      return if checksum_for_file(local_path) == response["ETag"]
      local_path.delete
      update(local_path, remote_path)
    end

    def checksum_for_file(path)
      return nil unless path.file?
      Digest::MD5.file(path).hexdigest
    end
  end
end
