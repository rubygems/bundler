class Net::HTTP

  alias request_without_samuel request
  def request(req, body = nil, &block)
    Samuel.log_request(self, req) do
      request_without_samuel(req, body, &block)
    end
  end

end
