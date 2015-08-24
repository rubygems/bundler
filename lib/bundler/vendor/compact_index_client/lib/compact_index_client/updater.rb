class Bundler::CompactIndexClient
  class Updater
    def initialize(fetcher)
      @fetcher = fetcher
    end

    def update(local_path, remote_path, retrying = nil)
      headers = {}

      if local_path.file?
        headers["If-None-Match"] = etag_for(local_path)
        headers["Range"] = "bytes=#{local_path.size}-"
      else
        # Fastly ignores Range when Accept-Encoding: gzip is set
        headers["Accept-Encoding"] = "gzip"
      end

      response = @fetcher.call(remote_path, headers)
      return if response.is_a?(Net::HTTPNotModified)

      if response["Content-Encoding"] == "gzip"
        content = Zlib::GzipReader.new(StringIO.new(response.body)).read
      else
        content = response.body
      end

      mode = response.is_a?(Net::HTTPPartialContent) ? "a" : "w"
      local_path.open(mode) {|f| f << content }

      if etag_for(local_path) != response["ETag"] && retrying.nil?
        local_path.delete
        update(local_path, remote_path, :retrying)
      else
        raise Bundler::HTTPError, "Checksum for file at #{local_path}" \
          "does not match checksum provided by server! Something is wrong."
      end
    end

    def etag_for(path)
      return nil unless path.file?
      '"' << Digest::MD5.file(path).hexdigest << '"'
    end
  end
end
