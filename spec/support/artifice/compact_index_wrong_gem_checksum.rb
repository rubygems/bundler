# frozen_string_literal: true
require File.expand_path("../compact_index", __FILE__)

Artifice.deactivate

class CompactIndexWrongGemChecksum < CompactIndexAPI
  get "/info/:name" do
    etag_response do
      gem = gems.find {|g| g.name == params[:name] }
      versions = gem ? gem.versions : []
      versions.each {|v| v.checksum = "checksum!" }
      CompactIndex.info(versions)
    end
  end
end

Artifice.activate_with(CompactIndexWrongGemChecksum)
