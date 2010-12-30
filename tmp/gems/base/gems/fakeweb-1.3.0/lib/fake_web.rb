require 'singleton'

require 'fake_web/ext/net_http'
require 'fake_web/registry'
require 'fake_web/response'
require 'fake_web/responder'
require 'fake_web/stub_socket'
require 'fake_web/utility'

FakeWeb::Utility.record_loaded_net_http_replacement_libs
FakeWeb::Utility.puts_warning_for_net_http_around_advice_libs_if_needed

module FakeWeb

  # Returns the version string for the copy of FakeWeb you have loaded.
  VERSION = '1.3.0'

  # Resets the FakeWeb Registry. This will force all subsequent web requests to
  # behave as real requests.
  def self.clean_registry
    Registry.instance.clean_registry
  end

  # Enables or disables real HTTP connections for requests that don't match
  # registered URIs.
  #
  # If you set <tt>FakeWeb.allow_net_connect = false</tt> and subsequently try
  # to make a request to a URI you haven't registered with #register_uri, a
  # NetConnectNotAllowedError will be raised. This is handy when you want to
  # make sure your tests are self-contained, or want to catch the scenario
  # when a URI is changed in implementation code without a corresponding test
  # change.
  #
  # When <tt>FakeWeb.allow_net_connect = true</tt> (the default), requests to
  # URIs not stubbed with FakeWeb are passed through to Net::HTTP.
  #
  # If you assign a +String+, +URI+, or +Regexp+ object, unstubbed requests
  # will be allowed if they match that value. This is useful when you want to
  # allow access to a local server for integration testing, while still
  # preventing your tests from using the internet.
  def self.allow_net_connect=(allowed)
    case allowed
    when String, URI, Regexp
      @allow_all_connections = false
      Registry.instance.register_passthrough_uri(allowed)
    else
      @allow_all_connections = allowed
      Registry.instance.remove_passthrough_uri
    end
  end

  # Enable pass-through to Net::HTTP by default.
  self.allow_net_connect = true

  # Returns +true+ if requests to URIs not registered with FakeWeb are passed
  # through to Net::HTTP for normal processing (the default). Returns +false+
  # if an exception is raised for these requests.
  #
  # If you've assigned a +String+, +URI+, or +Regexp+ to
  # <tt>FakeWeb.allow_net_connect=</tt>, you must supply a URI to check
  # against that filter. Otherwise, an ArgumentError will be raised.
  def self.allow_net_connect?(uri = nil)
    if Registry.instance.passthrough_uri_map.any?
      raise ArgumentError, "You must supply a URI to test" if uri.nil?
      Registry.instance.passthrough_uri_matches?(uri)
    else
      @allow_all_connections
    end
  end

  # This exception is raised if you set <tt>FakeWeb.allow_net_connect =
  # false</tt> and subsequently try to make a request to a URI you haven't
  # stubbed.
  class NetConnectNotAllowedError < StandardError; end;

  # This exception is raised if a Net::HTTP request matches more than one of
  # the stubs you've registered. To fix the problem, remove a duplicate
  # registration or disambiguate any regular expressions by making them more
  # specific.
  class MultipleMatchingURIsError < StandardError; end;

  # call-seq:
  #   FakeWeb.register_uri(method, uri, options)
  #
  # Register requests using the HTTP method specified by the symbol +method+
  # for +uri+ to be handled according to +options+. If you specify the method
  # <tt>:any</tt>, the response will be reigstered for any request for +uri+.
  # +uri+ can be a +String+, +URI+, or +Regexp+ object. +options+ must be either
  # a +Hash+ or an +Array+ of +Hashes+ (see below), which must contain one of
  # these two keys:
  #
  # <tt>:body</tt>::
  #   A string which is used as the body of the response. If the string refers
  #   to a valid filesystem path, the contents of that file will be read and used
  #   as the body of the response instead. (This used to be two options,
  #   <tt>:string</tt> and <tt>:file</tt>, respectively. These are now deprecated.)
  # <tt>:response</tt>:: 
  #   Either a <tt>Net::HTTPResponse</tt>, an +IO+, or a +String+ which is used
  #   as the full response for the request.
  # 
  #   The easier way by far is to pass the <tt>:response</tt> option to
  #   +register_uri+ as a +String+ or an (open for reads) +IO+ object which
  #   will be used as the complete HTTP response, including headers and body.
  #   If the string points to a readable file, this file will be used as the
  #   content for the request.
  # 
  #   To obtain a complete response document, you can use the +curl+ command,
  #   like so:
  #   
  #     curl -i http://example.com > response_from_example.com
  #
  #   which can then be used in your test environment like so:
  #
  #     FakeWeb.register_uri(:get, "http://example.com", :response => "response_from_example.com")
  #
  #   See the <tt>Net::HTTPResponse</tt>
  #   documentation[http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTPResponse.html]
  #   for more information on creating custom response objects.
  # 
  # +options+ may also be an +Array+ containing a list of the above-described
  # +Hash+. In this case, FakeWeb will rotate through each response. You can
  # optionally repeat a response more than once before rotating:
  #
  # <tt>:times</tt>::
  #   The number of times this response will be used before moving on to the
  #   next one. The last response will be repeated indefinitely, regardless of
  #   its <tt>:times</tt> parameter.
  #
  # Two optional arguments are also accepted:
  #
  # <tt>:status</tt>::
  #   Passing <tt>:status</tt> as a two-value array will set the response code
  #   and message. The defaults are <tt>200</tt> and <tt>OK</tt>, respectively.
  #   Example:
  #     FakeWeb.register_uri(:get, "http://example.com", :body => "Go away!", :status => [404, "Not Found"])
  # <tt>:exception</tt>::
  #   The argument passed via <tt>:exception</tt> will be raised when the
  #   specified URL is requested. Any +Exception+ class is valid. Example:
  #     FakeWeb.register_uri(:get, "http://example.com", :exception => Net::HTTPError)
  #
  # If you're using the <tt>:body</tt> response type, you can pass additional
  # options to specify the HTTP headers to be used in the response. Example:
  #
  #   FakeWeb.register_uri(:get, "http://example.com/index.txt", :body => "Hello", :content_type => "text/plain")
  #
  # You can also pass an array of header values to include a header in the
  # response more than once:
  #
  #   FakeWeb.register_uri(:get, "http://example.com", :set_cookie => ["name=value", "example=1"])
  def self.register_uri(*args)
    case args.length
    when 3
      Registry.instance.register_uri(*args)
    when 2
      print_missing_http_method_deprecation_warning(*args)
      Registry.instance.register_uri(:any, *args)
    else
      raise ArgumentError.new("wrong number of arguments (#{args.length} for 3)")
    end
  end

  # call-seq:
  #   FakeWeb.response_for(method, uri)
  #
  # Returns the faked Net::HTTPResponse object associated with +method+ and +uri+.
  def self.response_for(*args, &block) #:nodoc: :yields: response
    case args.length
    when 2
      Registry.instance.response_for(*args, &block)
    when 1
      print_missing_http_method_deprecation_warning(*args)
      Registry.instance.response_for(:any, *args, &block)
    else
      raise ArgumentError.new("wrong number of arguments (#{args.length} for 2)")
    end
  end

  # call-seq:
  #   FakeWeb.registered_uri?(method, uri)
  #
  # Returns true if a +method+ request for +uri+ is registered with FakeWeb.
  # Specify a method of <tt>:any</tt> to check against all HTTP methods.
  def self.registered_uri?(*args)
    case args.length
    when 2
      Registry.instance.registered_uri?(*args)
    when 1
      print_missing_http_method_deprecation_warning(*args)
      Registry.instance.registered_uri?(:any, *args)
    else
      raise ArgumentError.new("wrong number of arguments (#{args.length} for 2)")
    end
  end

  # Returns the request object from the last request made via Net::HTTP.
  def self.last_request
    @last_request
  end

  def self.last_request=(request) #:nodoc:
    @last_request = request
  end

  private

  def self.print_missing_http_method_deprecation_warning(*args)
    method = caller.first.match(/`(.*?)'/)[1]
    new_args = args.map { |a| a.inspect }.unshift(":any")
    new_args.last.gsub!(/^\{|\}$/, "").gsub!("=>", " => ") if args.last.is_a?(Hash)
    $stderr.puts
    $stderr.puts "Deprecation warning: FakeWeb requires an HTTP method argument (or use :any). Try this:"
    $stderr.puts "  FakeWeb.#{method}(#{new_args.join(', ')})"
    $stderr.puts "Called at #{caller[1]}"
  end
end
