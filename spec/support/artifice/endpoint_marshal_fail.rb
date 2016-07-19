# frozen_string_literal: true
require File.expand_path("../endpoint_fallback", __FILE__)

Artifice.deactivate

class Artifice::EndpointMarshalFail < Artifice::EndpointFallback
  get "/api/v1/dependencies" do
    "f0283y01hasf"
  end
end

Artifice.activate_with(Artifice::EndpointMarshalFail)
