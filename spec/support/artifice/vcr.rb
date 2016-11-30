# frozen_string_literal: true
require File.expand_path("../../path.rb", __FILE__)
include Spec::Path

$LOAD_PATH.unshift(*Dir[Spec::Path.base_system_gems.join("gems/{vcr}-*/lib")].map(&:to_s))

require "vcr"
require "vcr/request_handler"
require "vcr/extensions/net_http_response"

require "net/http"
if RUBY_VERSION < "1.9"
  begin
    require "net/https"
  rescue LoadError
    nil # net/https or openssl
  end
end # but only for 1.8

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path("../vcr_cassettes", __FILE__)
  config.preserve_exact_body_bytes do |_response|
    true
  end
  # config.debug_logger = File.open(File.expand_path("../vcr.log", __FILE__), "w")
end

VCR.insert_cassette \
  ENV.fetch("BUNDLER_SPEC_VCR_CASSETTE_NAME"),
  :record => :new_episodes,
  :match_requests_on => [:method, :uri, :query]

at_exit { VCR.eject_cassette }

class BundlerVCRHTTP < Net::HTTP
  # @private
  class RequestHandler < ::VCR::RequestHandler
    attr_reader :net_http, :request, :request_body, :response_block
    def initialize(net_http, request, request_body = nil, &response_block)
      @net_http = net_http
      @request = request
      @request_body = request_body
      @response_block = response_block
      @stubbed_response = nil
      @vcr_response = nil
      @recursing = false
    end

    def handle
      super
    ensure
      invoke_after_request_hook(@vcr_response) unless @recursing
    end

  private

    def on_recordable_request
      perform_request(net_http.started?, :record_interaction)
    end

    def on_stubbed_by_vcr_request
      status = stubbed_response.status
      headers = stubbed_response.headers
      body = stubbed_response.body

      response_string = []
      response_string << "HTTP/1.1 #{status.code} #{status.message}"

      headers.each do |header, value|
        response_string << "#{header}: #{value}"
      end

      response_string << "" << body

      response_io = ::Net::BufferedIO.new(StringIO.new(response_string.join("\n")))
      res = ::Net::HTTPResponse.read_new(response_io)

      res.reading_body(response_io, true) do
        yield res if block_given?
      end

      res
    end

    def on_ignored_request
      raise "no ignored requests allowed"
    end

    def perform_request(started, record_interaction = false)
      # Net::HTTP calls #request recursively in certain circumstances.
      # We only want to record the request when the request is started, as
      # that is the final time through #request.
      unless started
        @recursing = true
        request.instance_variable_set(:@__vcr_request_handler, recursive_request_handler)
        return net_http.request_without_vcr(request, request_body, &response_block)
      end

      net_http.request_without_vcr(request, request_body) do |response|
        @vcr_response = vcr_response_from(response)

        if record_interaction
          VCR.record_http_interaction VCR::HTTPInteraction.new(vcr_request, @vcr_response)
        end

        response.extend ::VCR::Net::HTTPResponse # "unwind" the response
        response_block.call(response) if response_block
      end
    end

    def uri
      @uri ||= begin
        protocol = net_http.use_ssl? ? "https" : "http"

        path = request.path
        path = URI.parse(request.path).request_uri if request.path =~ /^http/

        "#{protocol}://#{net_http.address}#{path}"
      end
    end

    def response_hash(response)
      (response.headers || {}).merge(
        :body   => response.body,
        :status => [response.status.code.to_s, response.status.message]
      )
    end

    def request_method
      request.method.downcase.to_sym
    end

    def vcr_request
      @vcr_request ||= VCR::Request.new \
        request_method,
        uri,
        (request_body || request.body),
        request.to_hash
    end

    def vcr_response_from(response)
      VCR::Response.new \
        VCR::ResponseStatus.new(response.code.to_i, response.message),
        response.to_hash,
        response.body,
        response.http_version
    end

    def recursive_request_handler
      @recursive_request_handler ||= RecursiveRequestHandler.new(
        @after_hook_typed_request.type, @stubbed_response, @vcr_request,
        @net_http, @request, @request_body, &@response_block
      )
    end
  end

  # @private
  class RecursiveRequestHandler < RequestHandler
    attr_reader :stubbed_response

    def initialize(request_type, stubbed_response, vcr_request, *args, &response_block)
      @request_type = request_type
      @stubbed_response = stubbed_response
      @vcr_request = vcr_request
      super(*args)
    end

    def handle
      set_typed_request_for_after_hook(@request_type)
      send "on_#{@request_type}_request"
    ensure
      invoke_after_request_hook(@vcr_response)
    end

    def request_type(*args)
      @request_type
    end
  end

  def request_with_vcr(request, *args, &block)
    handler = request.instance_eval do
      remove_instance_variable(:@__vcr_request_handler) if defined?(@__vcr_request_handler)
    end || RequestHandler.new(self, request, *args, &block)

    handler.handle
  end

  alias_method :request_without_vcr, :request
  alias_method :request, :request_with_vcr
end

# Replace Net::HTTP with our VCR subclass
::Net.class_eval do
  remove_const(:HTTP)
  const_set(:HTTP, BundlerVCRHTTP)
end
