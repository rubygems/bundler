# frozen_string_literal: true
require File.expand_path("../compact_index_api", __FILE__)

Artifice.deactivate

class Artifice::CompactIndexRedirects < Artifice::CompactIndexAPI
  get "/fetch/actual/gem/:id" do
    redirect "/fetch/actual/gem/#{params[:id]}"
  end

  get "/versions" do
    status 404
  end

  get "/api/v1/dependencies" do
    status 404
  end
end

Artifice.activate_with(Artifice::CompactIndexRedirects)
