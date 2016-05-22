# frozen_string_literal: true
require File.expand_path("../endpoint", __FILE__)

Artifice.deactivate

class EndpointNoGem < Endpoint
  get "/gems/:id" do
    halt 500
  end
end

Artifice.activate_with(EndpointNoGem)
