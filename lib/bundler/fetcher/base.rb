module Bundler
  class Fetcher
    class Base
      attr_reader :connection
      attr_reader :remote_uri
      attr_reader :fetch_uri
      attr_reader :display_uri

      def initialize(connection, remote_uri, fetch_uri, display_uri)
        raise 'Abstract class' if self.class == Base
        @connection = connection
        @remote_uri = remote_uri
        @fetch_uri = fetch_uri
        @display_uri = display_uri
      end

      def api_available?
        api_fetcher?
      end

      def api_fetcher?
        false
      end

      def fetch(uri, counter = 0)
        raise HTTPError, "Too many redirects" if counter >= Fetcher.redirect_limit

        response = request(uri)
        Bundler.ui.debug("HTTP #{response.code} #{response.message}")

        case response
        when Net::HTTPRedirection
          new_uri = URI.parse(response["location"])
          if new_uri.host == uri.host
            new_uri.user = uri.user
            new_uri.password = uri.password
          end
          fetch(new_uri, counter + 1)
        when Net::HTTPSuccess
          response.body
        when Net::HTTPRequestEntityTooLarge
          raise FallbackError, response.body
        when Net::HTTPUnauthorized
          raise AuthenticationRequiredError, remote_uri.host
        else
          raise HTTPError, "#{response.class}: #{response.body}"
        end
      end

      def request(uri)
        Bundler.ui.debug "HTTP GET #{uri}"
        req = Net::HTTP::Get.new uri.request_uri
        if uri.user
          user = CGI.unescape(uri.user)
          password = uri.password ? CGI.unescape(uri.password) : nil
          req.basic_auth(user, password)
        end
        connection.request(uri, req)
      rescue OpenSSL::SSL::SSLError
        raise CertificateFailureError.new(uri)
      rescue *HTTP_ERRORS => e
        Bundler.ui.trace e
        case e.message
        when /host down:/, /getaddrinfo: nodename nor servname provided/
          raise NetworkDownError, "Could not reach host #{uri.host}. Check your network " \
          "connection and try again."
        else
          raise HTTPError, "Network error while fetching #{uri}"
        end
      end

      def well_formed_dependency(name, *requirements)
        Gem::Dependency.new(name, *requirements)
      rescue ArgumentError => e
        illformed = 'Ill-formed requirement ["#<YAML::Syck::DefaultKey'
        raise e unless e.message.include?(illformed)
        puts # we shouldn't print the error message on the "fetching info" status line
        raise GemspecError,
          "Unfortunately, the gem #{s[:name]} (#{s[:number]}) has an invalid " \
          "gemspec. \nPlease ask the gem author to yank the bad version to fix " \
          "this issue. For more information, see http://bit.ly/syck-defaultkey."
      end
    end
  end
end
