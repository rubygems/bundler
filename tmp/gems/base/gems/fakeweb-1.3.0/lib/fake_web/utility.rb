module FakeWeb
  module Utility #:nodoc:

    def self.decode_userinfo_from_header(header)
      header.sub(/^Basic /, "").unpack("m").first
    end

    def self.encode_unsafe_chars_in_userinfo(userinfo)
      unsafe_in_userinfo = /[^#{URI::REGEXP::PATTERN::UNRESERVED};&=+$,]|^(#{URI::REGEXP::PATTERN::ESCAPED})/
      userinfo.split(":").map { |part| uri_escape(part, unsafe_in_userinfo) }.join(":")
    end

    def self.strip_default_port_from_uri(uri)
      case uri
      when %r{^http://}  then uri.sub(%r{:80(/|$)}, '\1')
      when %r{^https://} then uri.sub(%r{:443(/|$)}, '\1')
      else uri
      end
    end

    # Returns a string with a normalized version of a Net::HTTP request's URI.
    def self.request_uri_as_string(net_http, request)
      protocol = net_http.use_ssl? ? "https" : "http"

      path = request.path
      path = URI.parse(request.path).request_uri if request.path =~ /^http/

      if request["authorization"] =~ /^Basic /
        userinfo = FakeWeb::Utility.decode_userinfo_from_header(request["authorization"])
        userinfo = FakeWeb::Utility.encode_unsafe_chars_in_userinfo(userinfo) + "@"
      else
        userinfo = ""
      end

      uri = "#{protocol}://#{userinfo}#{net_http.address}:#{net_http.port}#{path}"
    end

    # Wrapper for URI escaping that switches between URI::Parser#escape and
    # URI.escape for 1.9-compatibility
    def self.uri_escape(*args)
      if URI.const_defined?(:Parser)
        URI::Parser.new.escape(*args)
      else
        URI.escape(*args)
      end
    end

    def self.produce_side_effects_of_net_http_request(request, body)
      request.set_body_internal(body)
      request.content_length = request.body.length unless request.body.nil?
    end

    def self.puts_warning_for_net_http_around_advice_libs_if_needed
      libs = {"Samuel" => defined?(Samuel)}
      warnings = libs.select { |_, loaded| loaded }.map do |name, _|
        <<-TEXT.gsub(/ {10}/, '')
          \e[1mWarning: FakeWeb was loaded after #{name}\e[0m
          * #{name}'s code is being ignored when a request is handled by FakeWeb,
            because both libraries work by patching Net::HTTP.
          * To fix this, just reorder your requires so that FakeWeb is before #{name}.
        TEXT
      end
      $stderr.puts "\n" + warnings.join("\n") + "\n" if warnings.any?
    end

    def self.record_loaded_net_http_replacement_libs
      libs = {"RightHttpConnection" => defined?(RightHttpConnection)}
      @loaded_net_http_replacement_libs = libs.map { |name, loaded| name if loaded }.compact
    end

    def self.puts_warning_for_net_http_replacement_libs_if_needed
      libs = {"RightHttpConnection" => defined?(RightHttpConnection)}
      warnings = libs.select { |_, loaded| loaded }.
                    reject { |name, _| @loaded_net_http_replacement_libs.include?(name) }.
                    map do |name, _|
        <<-TEXT.gsub(/ {10}/, '')
          \e[1mWarning: #{name} was loaded after FakeWeb\e[0m
          * FakeWeb's code is being ignored, because #{name} replaces parts of
            Net::HTTP without deferring to other libraries. This will break Net::HTTP requests.
          * To fix this, just reorder your requires so that #{name} is before FakeWeb.
        TEXT
      end
      $stderr.puts "\n" + warnings.join("\n") + "\n" if warnings.any?
    end

  end
end
