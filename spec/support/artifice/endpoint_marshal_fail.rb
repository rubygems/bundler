require File.expand_path("../endpoint", __FILE__)

Artifice.deactivate

class EndpointMarshalFail < Endpoint
  get "/api/v1/dependencies" do
    "f0283y01hasf"
  end
end

Artifice.activate_with(EndpointMarshalFail)
