# frozen_string_literal: true
require File.expand_path("../compact_index_api", __FILE__)

Artifice.deactivate

class Artifice::CompactIndexBasicAuthentication < Artifice::CompactIndexAPI
  before do
    unless env["HTTP_AUTHORIZATION"]
      halt 401, "Authentication info not supplied"
    end
  end
end

Artifice.activate_with(Artifice::CompactIndexBasicAuthentication)
