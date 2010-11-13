require File.expand_path("../endpoint", __FILE__)

Artifice.deactivate

class EndpointRedirect < Endpoint
  get "/fetch/actual/gem/:id" do
    redirect "/fetch/actual/gem/#{params[:id]}"
  end
end

Artifice.activate_with(EndpointRedirect)
