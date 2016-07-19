# frozen_string_literal: true
require File.expand_path("../compact_index_api", __FILE__)

Artifice.deactivate

class Artifice::CompactIndexForbidden < Artifice::CompactIndexAPI
  get "/versions" do
    halt 403
  end
end

Artifice.activate_with(Artifice::CompactIndexForbidden)
