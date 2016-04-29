# frozen_string_literal: true
require "stringio"
require "zlib"

class Bundler::CompactIndexClient
  class Updater
    class MisMatchedChecksumError < Error
      def initialize(path, server_checksum, local_checksum)
        @path = path
        @server_checksum = server_checksum
        @local_checksum = local_checksum
      end

      def message
        "The checksum of /#{@path} does not match the checksum provided by the server! Something is wrong " \
          "(local checksum is #{@local_checksum.inspect}, was expecting #{@server_checksum.inspect})."
      end
    end

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

      content = response.body
      if response["Content-Encoding"] == "gzip"
        content = Zlib::GzipReader.new(StringIO.new(content)).read
      end

      mode = response.is_a?(Net::HTTPPartialContent) ? "a" : "w"
      local_path.open(mode) {|f| f << content }

      response_etag = response["ETag"]
      return if etag_for(local_path) == response_etag

      if retrying.nil?
        local_path.delete
        update(local_path, remote_path, :retrying)
      else
        raise MisMatchedChecksumError.new(remote_path, response_etag, etag_for(local_path))
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
