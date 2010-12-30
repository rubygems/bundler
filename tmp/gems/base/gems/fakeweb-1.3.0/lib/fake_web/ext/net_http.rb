require 'net/http'
require 'net/https'
require 'stringio'

module Net  #:nodoc: all

  class BufferedIO
    def initialize_with_fakeweb(io, debug_output = nil)
      @read_timeout = 60
      @rbuf = ''
      @debug_output = debug_output

      @io = case io
      when Socket, OpenSSL::SSL::SSLSocket, IO
        io
      when String
        if !io.include?("\0") && File.exists?(io) && !File.directory?(io)
          File.open(io, "r")
        else
          StringIO.new(io)
        end
      end
      raise "Unable to create local socket" unless @io
    end
    alias_method :initialize_without_fakeweb, :initialize
    alias_method :initialize, :initialize_with_fakeweb
  end

  class HTTP
    class << self
      def socket_type_with_fakeweb
        FakeWeb::StubSocket
      end
      alias_method :socket_type_without_fakeweb, :socket_type
      alias_method :socket_type, :socket_type_with_fakeweb
    end

    def request_with_fakeweb(request, body = nil, &block)
      FakeWeb.last_request = request

      uri = FakeWeb::Utility.request_uri_as_string(self, request)
      method = request.method.downcase.to_sym

      if FakeWeb.registered_uri?(method, uri)
        @socket = Net::HTTP.socket_type.new
        FakeWeb::Utility.produce_side_effects_of_net_http_request(request, body)
        FakeWeb.response_for(method, uri, &block)
      elsif FakeWeb.allow_net_connect?(uri)
        connect_without_fakeweb
        request_without_fakeweb(request, body, &block)
      else
        uri = FakeWeb::Utility.strip_default_port_from_uri(uri)
        raise FakeWeb::NetConnectNotAllowedError,
              "Real HTTP connections are disabled. Unregistered request: #{request.method} #{uri}"
      end
    end
    alias_method :request_without_fakeweb, :request
    alias_method :request, :request_with_fakeweb


    def connect_with_fakeweb
      unless @@alredy_checked_for_net_http_replacement_libs ||= false
        FakeWeb::Utility.puts_warning_for_net_http_replacement_libs_if_needed
        @@alredy_checked_for_net_http_replacement_libs = true
      end
      nil
    end
    alias_method :connect_without_fakeweb, :connect
    alias_method :connect, :connect_with_fakeweb
  end

end
