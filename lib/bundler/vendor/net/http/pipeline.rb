require 'net/http'

##
# An HTTP/1.1 pipelining implementation atop Net::HTTP.  This library is
# compliant with RFC 2616 8.1.2.2.
#
# Pipeline allows you to create a bunch of requests then send them all to an
# HTTP/1.1 server without waiting for responses.  The server will return HTTP
# responses in-order.
#
# Net::HTTP::Pipeline does not assume the server supports pipelining.  If you
# know the server supports pipelining you can set Net::HTTP#pipelining to
# true.
#
# = Example
#
#   require 'net/http/pipeline'
#
#   Net::HTTP.start 'localhost' do |http|
#     requests = []
#     requests << Net::HTTP::Get.new('/')
#     requests << Net::HTTP::Get.new('/')
#     requests << Net::HTTP::Get.new('/')
#
#     http.pipeline requests do |res|
#       puts res.code
#       puts res.body[0..60].inspect
#       puts
#     end
#   end

module Net::HTTP::Pipeline

  ##
  # The version of net-http-pipeline you are using

  VERSION = '1.0.1'

  ##
  # Pipeline error class

  class Error < RuntimeError

    ##
    # Remaining requests that have not been sent to the HTTP server

    attr_reader :requests

    ##
    # Retrieved responses up to the error point

    attr_reader :responses

    ##
    # Creates a new Error with +message+, a list of +requests+ that have not
    # been sent to the server and a list of +responses+ that have been
    # retrieved from the server.

    def initialize message, requests, responses
      super message

      @requests = requests
      @responses = responses
    end

  end

  ##
  # Raised when an invalid version is given

  class VersionError < Error
    ##
    # Creates a new VersionError with a list of +requests+ that have not been
    # sent to the server and a list of +responses+ that have been retrieved
    # from the server.

    def initialize requests, responses
      super 'HTTP/1.1 or newer required', requests, responses
    end
  end

  ##
  # Raised when the server appears to not support persistent connections

  class PersistenceError < Error
    ##
    # Creates a new PersistenceError with a list of +requests+ that have not
    # been sent to the server and a list of +responses+ that have been
    # retrieved from the server.

    def initialize requests, responses
      super 'persistent connections required', requests, responses
    end
  end

  ##
  # Raised when the server appears to not support pipelining connections

  class PipelineError < Error
    ##
    # Creates a new PipelineError with a list of +requests+ that have not been
    # sent to the server and a list of +responses+ that have been retrieved
    # from the server.

    def initialize requests, responses
      super 'pipeline connections are not supported', requests, responses
    end
  end

  ##
  # Raised if an error occurs while reading responses.

  class ResponseError < Error
    ##
    # The original exception

    attr_accessor :original

    ##
    # Creates a new ResponseError with an original +exception+, a list of
    # +requests+ that were in-flight and a list of +responses+ that have been
    # retrieved from the server.

    def initialize exception, requests, responses
      @original = exception
      message = "error handling responses: #{original} (#{original.class})"
      super message, requests, responses
    end
  end

  ##
  # Pipelining capability accessor.
  #
  # Pipeline assumes servers do not support pipelining by default.  The first
  # request is not pipelined while Pipeline ensures that the server is
  # HTTP/1.1 or newer and defaults to persistent connections.
  #
  # If you know the server is HTTP/1.1 and defaults to persistent
  # connections you can set this to true when you create the Net::HTTP object.

  attr_accessor :pipelining

  ##
  # Is +req+ idempotent according to RFC 2616?

  def idempotent? req
    case req
    when Net::HTTP::Delete, Net::HTTP::Get, Net::HTTP::Head,
         Net::HTTP::Options, Net::HTTP::Put, Net::HTTP::Trace then
      true
    end
  end

  ##
  # Pipelines +requests+ to the HTTP server yielding responses if a block is
  # given.  Returns all responses recieved.
  #
  # The Net::HTTP connection must be started before calling #pipeline.
  #
  # Raises an exception if the connection is not pipeline-capable or if the
  # HTTP session has not been started.

  def pipeline requests, &block # :yields: response
    responses = []

    raise Error.new('Net::HTTP not started', requests, responses) unless
      started?

    raise VersionError.new(requests, responses) if '1.1' > @curr_http_version

    pipeline_check requests, responses, &block

    retried = responses.length

    until requests.empty? do
      begin
        in_flight = pipeline_send requests

        pipeline_receive in_flight, responses, &block
      rescue Net::HTTP::Pipeline::ResponseError => e
        e.requests.reverse_each do |request|
          requests.unshift request
        end

        raise if responses.length == retried or not idempotent? requests.first

        retried = responses.length

        pipeline_reset requests, responses

        retry
      end
    end

    responses
  end

  ##
  # Ensures the connection supports pipelining.
  #
  # If the server has not been tested for pipelining support one of the
  # +requests+ will be consumed and placed in +responses+.
  #
  # A VersionError will be raised if the server is not HTTP/1.1 or newer.
  #
  # A PersistenceError will be raised if the server does not support
  # persistent connections.
  #
  # A PipelineError will be raised if the it was previously determined that
  # the server does not support pipelining.

  def pipeline_check requests, responses
    if instance_variable_defined? :@pipelining then
      return if @pipelining
      raise PipelineError.new(requests, responses) unless @pipelining
    else
      @pipelining = false
    end

    req = requests.shift
    retried = false

    begin
      res = request req
    rescue Timeout::Error, EOFError, Errno::ECONNABORTED, Errno::ECONNRESET,
           Errno::EPIPE, Net::HTTPBadResponse, IOError => e
      if retried then
        requests.unshift req
        raise ResponseError.new(e, requests, responses)
      end

      retried = true

      pipeline_reset requests, responses

      retry
    end

    responses << res

    yield res if block_given?

    @pipelining = pipeline_keep_alive? res

    if '1.1' > @curr_http_version then
      @pipelining = false
      raise VersionError.new(requests, responses)
    elsif not @pipelining then
      raise PersistenceError.new(requests, responses)
    end
  end

  ##
  # Updates the HTTP version and ensures the connection has keep-alive.

  def pipeline_end_transport res
    @curr_http_version = res.http_version

    if @socket.closed? then
      D 'Conn socket closed on pipeline'
    elsif pipeline_keep_alive? res then
      D 'Conn pipeline keep-alive'
    else
      D 'Conn close on pipeline'
      @socket.close
    end
  end

  ##
  # Closes the connection and rescues any IOErrors this may cause

  def pipeline_finish
    finish
  rescue IOError
  end

  if Net::HTTPResponse.allocate.respond_to? :connection_close? then
    ##
    # Checks for an connection close header

    def pipeline_keep_alive? res
      not res.connection_close?
    end
  else
    def pipeline_keep_alive? res
      not res['connection'].to_s =~ /close/i
    end
  end

  ##
  # Receives HTTP responses for +in_flight+ requests and adds them to
  # +responses+

  def pipeline_receive in_flight, responses
    while req = in_flight.shift do
      begin
        begin
          res = Net::HTTPResponse.read_new @socket
        end while res.kind_of? Net::HTTPContinue

        res.reading_body @socket, req.response_body_permitted? do
          responses << res
          yield res if block_given?
        end

        pipeline_end_transport res
      rescue StandardError, Timeout::Error
        in_flight.unshift req
        raise
      end
    end

    responses
  rescue Timeout::Error, EOFError, Errno::ECONNABORTED, Errno::ECONNRESET,
         Errno::EPIPE, Net::HTTPBadResponse, IOError => e
    pipeline_finish

    raise ResponseError.new(e, in_flight, responses)
  end

  ##
  # Resets this connection

  def pipeline_reset requests, responses
    pipeline_finish

    start
  rescue Errno::ECONNREFUSED
    raise Error.new("connection refused: #{address}:#{port}", requests,
                    responses)
  rescue Errno::EHOSTDOWN
    raise Error.new("host down: #{address}:#{port}", requests, responses)
  end

  ##
  # Sends +requests+ to the HTTP server and removes them from the +requests+
  # list.  Returns the requests that have been pipelined and are in-flight.
  #
  # If a non-idempotent request is first in +requests+ it will be sent and no
  # further requests will be pipelined.
  #
  # If a non-idempotent request is encountered after an idempotent request it
  # will not be sent.

  def pipeline_send requests
    in_flight = []

    while req = requests.shift do
      idempotent = idempotent? req

      unless idempotent or in_flight.empty? then
        requests.unshift req
        break
      end

      begin_transport req
      req.exec @socket, @curr_http_version, edit_path(req.path)
      in_flight << req

      break unless idempotent
    end

    in_flight
  end

end

class Net::HTTP

  ##
  # Adds pipeline support to Net::HTTP

  include Pipeline

end

