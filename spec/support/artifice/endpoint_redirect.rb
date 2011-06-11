require File.expand_path("../endpoint", __FILE__)

Artifice.deactivate

class EndpointRedirect < Endpoint
  get "/fetch/actual/gem/:id" do
    redirect "/fetch/actual/gem/#{params[:id]}"
  end

  get "/specs.4.8.gz" do
    File.read("#{gem_repo1}/specs.4.8.gz")
  end

  get "/api/v1/dependencies" do
    status 404
  end
end

Artifice.activate_with(EndpointRedirect)
