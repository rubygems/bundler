require 'bundler/vendored_persistent'
require 'securerandom'
require 'cgi'

module Bundler

  # Handles all the fetching with the rubygems server
  class Fetcher
    # This error is raised when it looks like the network is down
    class NetworkDownError < HTTPError; end
    # This error is raised if the API returns a 413 (only printed in verbose)
    class FallbackError < HTTPError; end
    # This is the error raised if OpenSSL fails the cert verification
    class CertificateFailureError < HTTPError
      def initialize(remote_uri)
        super "Could not verify the SSL certificate for #{remote_uri}.\nThere" \
          " is a chance you are experiencing a man-in-the-middle attack, but" \
          " most likely your system doesn't have the CA certificates needed" \
          " for verification. For information about OpenSSL certificates, see" \
          " bit.ly/ruby-ssl. To connect without using SSL, edit your Gemfile" \
          " sources and change 'https' to 'http'."
      end
    end
    # This is the error raised when a source is HTTPS and OpenSSL didn't load
    class SSLError < HTTPError
      def initialize(msg = nil)
        super msg || "Could not load OpenSSL.\n" \
            "You must recompile Ruby with OpenSSL support or change the sources in your " \
            "Gemfile from 'https' to 'http'. Instructions for compiling with OpenSSL " \
            "using RVM are available at rvm.io/packages/openssl."
      end
    end
    # This error is raised if HTTP authentication is required, but not provided.
    class AuthenticationRequiredError < HTTPError
      def initialize(remote_uri)
        super "Authentication is required for #{remote_uri}.\n" \
          "Please supply credentials for this source. You can do this by running:\n" \
          " bundle config #{remote_uri} username:password"
      end
    end
    # This error is raised if HTTP authentication is provided, but incorrect.
    class BadAuthenticationError < HTTPError
      def initialize(remote_uri)
        super "Bad username or password for #{remote_uri}.\n" \
          "Please double-check your credentials and correct them."
      end
    end

    # Exceptions classes that should bypass retry attempts. If your password didn't work the
    # first time, it's not going to the third time.
    AUTH_ERRORS = [AuthenticationRequiredError, BadAuthenticationError]

    class << self
      attr_accessor :disable_endpoint, :api_timeout, :redirect_limit, :max_retries

      Fetcher.redirect_limit = 5  # How many redirects to allow in one request
      Fetcher.api_timeout    = 10 # How long to wait for each API call
      Fetcher.max_retries    = 3  # How many retries for the API call

      def download_gem_from_uri(spec, uri)
        spec.fetch_platform

        download_path = Bundler.requires_sudo? ? Bundler.tmp(spec.full_name) : Bundler.rubygems.gem_dir
        gem_path = "#{Bundler.rubygems.gem_dir}/cache/#{spec.full_name}.gem"

        FileUtils.mkdir_p("#{download_path}/cache")
        Bundler.rubygems.download_gem(spec, uri, download_path)

        if Bundler.requires_sudo?
          Bundler.mkdir_p "#{Bundler.rubygems.gem_dir}/cache"
          Bundler.sudo "mv #{Bundler.tmp(spec.full_name)}/cache/#{spec.full_name}.gem #{gem_path}"
        end

        gem_path
      end

      def user_agent
        @user_agent ||= begin
          ruby = Bundler.ruby_version

          agent = "bundler/#{Bundler::VERSION}"
          agent << " rubygems/#{Gem::VERSION}"
          agent << " ruby/#{ruby.version}"
          agent << " (#{ruby.host})"
          agent << " command/#{ARGV.first}"

          if ruby.engine != "ruby"
            # engine_version raises on unknown engines
            engine_version = ruby.engine_version rescue "???"
            agent << " #{ruby.engine}/#{engine_version}"
          end

          agent << " options/#{Bundler.settings.all.join(",")}"

          # add a random ID so we can consolidate runs server-side
          agent << " " << SecureRandom.hex(8)

          # add any user agent strings set in the config
          extra_ua = Bundler.settings[:user_agent]
          agent << " " << extra_ua if extra_ua

          agent
        end
      end

    end

    def initialize(remote)
      @remote = remote

      Socket.do_not_reverse_lookup = true
      connection # create persistent connection
    end

    def uri
      @remote.anonymized_uri
    end

    # fetch a gem specification
    def fetch_spec(spec)
      spec = spec - [nil, 'ruby', '']
      spec_file_name = "#{spec.join '-'}.gemspec"

      uri = URI.parse("#{remote_uri}#{Gem::MARSHAL_SPEC_DIR}#{spec_file_name}.rz")
      if uri.scheme == 'file'
        Bundler.load_marshal Gem.inflate(Gem.read_binary(uri.path))
      elsif cached_spec_path = gemspec_cached_path(spec_file_name)
        Bundler.load_gemspec(cached_spec_path)
      else
        Bundler.load_marshal Gem.inflate(fetchers.first.fetch uri)
      end
    rescue MarshalError
      raise HTTPError, "Gemspec #{spec} contained invalid data.\n" \
        "Your network or your gem server is probably having issues right now."
    end

    # return the specs in the bundler format as an index
    def specs(gem_names, source)
      old = Bundler.rubygems.sources
      index = Index.new

      specs = {}
      fetchers.dup.each do |f|
        unless f.api_fetcher? && !gem_names
          break if specs = f.specs(gem_names)
        end
        fetchers.delete(f)
      end
      @use_api = false if fetchers.none?(&:api_fetcher?)

      specs[remote_uri].each do |name, version, platform, dependencies|
        next if name == 'bundler'
        spec = nil
        if dependencies
          spec = EndpointSpecification.new(name, version, platform, dependencies)
        else
          spec = RemoteSpecification.new(name, version, platform, self)
        end
        spec.source = source
        spec.remote = @remote
        index << spec
      end

      index
    rescue CertificateFailureError
      Bundler.ui.info "" if gem_names && use_api # newline after dots
      raise
    ensure
      Bundler.rubygems.sources = old
    end

    def use_api
      return @use_api if defined?(@use_api)

      if remote_uri.scheme == "file" || Bundler::Fetcher.disable_endpoint
        @use_api = false
      else
        fetchers.reject! { |f| f.api_fetcher? && !f.api_available? }
        @use_api = fetchers.any?(&:api_fetcher?)
      end
    end

    def inspect
      "#<#{self.class}:0x#{object_id} uri=#{uri}>"
    end

    def fetchers
      @fetchers ||= FETCHERS.map { |f| f.new(connection, remote_uri, fetch_uri, uri) }
    end

  private

    class FetcherImpl
      attr_reader :connection
      attr_reader :remote_uri
      attr_reader :fetch_uri
      attr_reader :display_uri

      def initialize(connection, remote_uri, fetch_uri, display_uri)
        raise 'Abstract class' if self.class == FetcherImpl
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

    class DependencyFetcher < FetcherImpl
      def api_available?
        fetch(dependency_api_uri)
      rescue NetworkDownError => e
        raise HTTPError, e.message
      rescue AuthenticationRequiredError
        # We got a 401 from the server. Just fail.
        raise
      rescue HTTPError
      end

      def api_fetcher?
        true
      end

      def specs(gem_names, full_dependency_list = [], last_spec_list = [])
        query_list = gem_names - full_dependency_list

        # only display the message on the first run
        if Bundler.ui.debug?
          Bundler.ui.debug "Query List: #{query_list.inspect}"
        else
          Bundler.ui.info ".", false
        end

        return {remote_uri => last_spec_list} if query_list.empty?

        remote_specs = Bundler::Retry.new("dependency api", AUTH_ERRORS).attempts do
          dependency_specs(query_list)
        end

        spec_list, deps_list = remote_specs
        returned_gems = spec_list.map(&:first).uniq
        specs(deps_list, full_dependency_list + returned_gems, spec_list + last_spec_list)
      rescue HTTPError, MarshalError, GemspecError
        Bundler.ui.info "" unless Bundler.ui.debug? # new line now that the dots are over
        Bundler.ui.debug "could not fetch from the dependency API, trying the full index"
        return nil
      end

      def dependency_specs(gem_names)
        Bundler.ui.debug "Query Gemcutter Dependency Endpoint API: #{gem_names.join(',')}"
        gem_list = []
        deps_list = []

        gem_names.each_slice(Source::Rubygems::API_REQUEST_SIZE) do |names|
          marshalled_deps = fetch dependency_api_uri(names)
          gem_list += Bundler.load_marshal(marshalled_deps)
        end

        spec_list = gem_list.map do |s|
          dependencies = s[:dependencies].map do |name, requirement|
            dep = well_formed_dependency(name, requirement.split(", "))
            deps_list << dep.name
            dep
          end

          [s[:name], Gem::Version.new(s[:number]), s[:platform], dependencies]
        end

        [spec_list, deps_list.uniq]
      end

      def dependency_api_uri(gem_names = [])
        uri = fetch_uri + "api/v1/dependencies"
        uri.query = "gems=#{URI.encode(gem_names.join(","))}" if gem_names.any?
        uri
      end
    end

    class IndexFetcher < FetcherImpl
      def specs(_gem_names)
        old_sources = Bundler.rubygems.sources
        Bundler.rubygems.sources = [remote_uri.to_s]
        Bundler.rubygems.fetch_all_remote_specs
      rescue Gem::RemoteFetcher::FetchError, OpenSSL::SSL::SSLError => e
        case e.message
        when /certificate verify failed/
          raise CertificateFailureError.new(display_uri)
        when /401/
          raise AuthenticationRequiredError, remote_uri
        when /403/
          if remote_uri.userinfo
            raise BadAuthenticationError, remote_uri
          else
            raise AuthenticationRequiredError, remote_uri
          end
        else
          Bundler.ui.trace e
          raise HTTPError, "Could not fetch specs from #{display_uri}"
        end
      ensure
        Bundler.rubygems.sources = old_sources
      end
    end

    FETCHERS = [DependencyFetcher, IndexFetcher]

    def connection
      @connection ||= begin
        needs_ssl = remote_uri.scheme == "https" ||
          Bundler.settings[:ssl_verify_mode] ||
          Bundler.settings[:ssl_client_cert]
        raise SSLError if needs_ssl && !defined?(OpenSSL::SSL)

        con = Net::HTTP::Persistent.new 'bundler', :ENV

        if remote_uri.scheme == "https"
          con.verify_mode = (Bundler.settings[:ssl_verify_mode] ||
            OpenSSL::SSL::VERIFY_PEER)
          con.cert_store = bundler_cert_store
        end

        if Bundler.settings[:ssl_client_cert]
          pem = File.read(Bundler.settings[:ssl_client_cert])
          con.cert = OpenSSL::X509::Certificate.new(pem)
          con.key  = OpenSSL::PKey::RSA.new(pem)
        end

        con.read_timeout = @api_timeout
        con.override_headers["User-Agent"] = self.class.user_agent
        con
      end
    end

    # cached gem specification path, if one exists
    def gemspec_cached_path spec_file_name
      paths = Bundler.rubygems.spec_cache_dirs.map { |dir| File.join(dir, spec_file_name) }
      paths = paths.select {|path| File.file? path }
      paths.first
    end

    HTTP_ERRORS = [
      Timeout::Error, EOFError, SocketError, Errno::ENETDOWN,
      Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EAGAIN,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
      Net::HTTP::Persistent::Error
    ]

    def bundler_cert_store
      store = OpenSSL::X509::Store.new
      if Bundler.settings[:ssl_ca_cert]
        if File.directory? Bundler.settings[:ssl_ca_cert]
          store.add_path Bundler.settings[:ssl_ca_cert]
        else
          store.add_file Bundler.settings[:ssl_ca_cert]
        end
      else
        store.set_default_paths
        certs = File.expand_path("../ssl_certs/*.pem", __FILE__)
        Dir.glob(certs).each { |c| store.add_file c }
      end
      store
    end

  private

    def fetch_uri
      @fetch_uri ||= begin
        if remote_uri.host == "rubygems.org"
          uri = remote_uri.dup
          uri.host = "bundler.rubygems.org"
          uri
        else
          remote_uri
        end
      end
    end

    def remote_uri
      @remote.uri
    end
  end
end
