# frozen_string_literal: true
require File.expand_path("../compact_index_api", __FILE__)

Artifice.deactivate

class Artifice::CompactIndexConcurrentDownload < Artifice::CompactIndexAPI
  get "/versions" do
    versions = File.join(Bundler.rubygems.user_home, ".bundle", "cache", "compact_index",
      "localgemserver.test.80.dd34752a738ee965a2a4298dc16db6c5", "versions")

    # Verify the original (empty) content hasn't been deleted, e.g. on a retry
    File.read(versions) == "" || raise("Original file should be present and empty")

    # Verify this is only requested once for a partial download
    env["HTTP_RANGE"] || raise("Missing Range header for expected partial download")

    # Overwrite the file in parallel, which should be then overwritten
    # after a successful download to prevent corruption
    File.open(versions, "w") {|f| f.puts "another process" }

    etag_response do
      file = tmp("versions.list")
      file.delete if file.file?
      file = CompactIndex::VersionsFile.new(file.to_s)
      file.update_with(gems)
      CompactIndex.versions(file, nil, {})
    end
  end
end

Artifice.activate_with(Artifice::CompactIndexConcurrentDownload)
