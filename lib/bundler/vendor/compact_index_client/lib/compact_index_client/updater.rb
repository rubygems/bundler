require "stringio"
require "zlib"

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

      return if etag_for(local_path) == response["ETag"]

      if retrying.nil?
        local_path.delete
        update(local_path, remote_path, :retrying)
      else
        raise Bundler::HTTPError, "Checksum of /#{remote_path} " \
          "does not match the checksum provided by server! Something is wrong."
      end
    end

    def etag_for(path)
      sum = checksum_for_file(path)
      sum ? '"' << sum << '"' : nil
    end

    def checksum_for_file(path)
      return nil unless path.file?
      Digest::MD5.file(path).hexdigest
    end
  end
end
