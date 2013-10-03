require 'bundler/vendored_persistent'
require 'securerandom'

module Bundler

  # Handles all the fetching with the rubygems server
  class Fetcher
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

    class << self
      attr_accessor :disable_endpoint, :api_timeout, :redirect_limit, :max_retries

      def fetch(spec)
        if spec.source_uri
          path = download_gem_from_uri(spec, spec.source_uri)
          s = Bundler.rubygems.spec_from_gem(path, Bundler.settings["trust-policy"])
          spec.__swap__(s)
        end
      end

      def download_gem_from_uri(spec, uri)
        spec.fetch_platform

        download_path = Bundler.requires_sudo? ? Bundler.tmp : Bundler.rubygems.gem_dir
        gem_path = "#{Bundler.rubygems.gem_dir}/cache/#{spec.full_name}.gem"

        FileUtils.mkdir_p("#{download_path}/cache")
        Bundler.rubygems.download_gem(spec, uri, download_path)

        if Bundler.requires_sudo?
          Bundler.mkdir_p "#{Bundler.rubygems.gem_dir}/cache"
          Bundler.sudo "mv #{Bundler.tmp}/cache/#{spec.full_name}.gem #{gem_path}"
        end

        gem_path
      end

      def user_agent
        @user_agent ||= begin
          ruby = Bundler.ruby_version

          agent = "bundler/#{Bundler::VERSION}"
          agent += " rubygems/#{Gem::VERSION}"
          agent += " ruby/#{ruby.version}"
          agent += " (#{ruby.host})"
          agent += " command/#{ARGV.first}"

          if ruby.engine != "ruby"
            # engine_version raises on unknown engines
            engine_version = ruby.engine_version rescue "???"
            agent += " #{ruby.engine}/#{engine_version}"
          end
          # add a random ID so we can consolidate runs server-side
          agent << " " << SecureRandom.hex(8)
        end
      end

    end

    def initialize(remote_uri)
      # How many redirects to allew in one request
      @redirect_limit = 5
      # How long to wait for each gemcutter API call
      @api_timeout = 10
      # How many retries for the gemcutter API call
      @max_retries = 3

      @remote_uri = remote_uri
      @public_uri = remote_uri.dup
      @public_uri.user, @public_uri.password = nil, nil # don't print these

      Socket.do_not_reverse_lookup = true
    end

    def connection
      return @connection if @connection

      needs_ssl = @remote_uri.scheme == "https" ||
        Bundler.settings[:ssl_verify_mode] ||
        Bundler.settings[:ssl_client_cert]
      raise SSLError if needs_ssl && !defined?(OpenSSL)

      @connection = Net::HTTP::Persistent.new 'bundler', :ENV

      if @remote_uri.scheme == "https"
        @connection.verify_mode = (Bundler.settings[:ssl_verify_mode] ||
          OpenSSL::SSL::VERIFY_PEER)
        @connection.cert_store = bundler_cert_store
      end

      if Bundler.settings[:ssl_client_cert]
        pem = File.read(Bundler.settings[:ssl_client_cert])
        @connection.cert = OpenSSL::X509::Certificate.new(pem)
        @connection.key  = OpenSSL::PKey::RSA.new(pem)
      end

      @connection.read_timeout = @api_timeout
      @connection.override_headers["User-Agent"] = self.class.user_agent

      @connection
    end

    def uri
      @public_uri
    end

    # fetch a gem specification
    def fetch_spec(spec)
      spec = spec - [nil, 'ruby', '']
      spec_file_name = "#{spec.join '-'}.gemspec"

      uri = URI.parse("#{@remote_uri}#{Gem::MARSHAL_SPEC_DIR}#{spec_file_name}.rz")
      if uri.scheme == 'file'
        Bundler.load_marshal Gem.inflate(Gem.read_binary(uri.path))
      elsif cached_spec_path = gemspec_cached_path(spec_file_name)
        Bundler.load_gemspec(cached_spec_path)
      else
        Bundler.load_marshal Gem.inflate(fetch(uri))
      end
    rescue MarshalError => e
      raise HTTPError, "Gemspec #{spec} contained invalid data.\n" \
        "Your network or your gem server is probably having issues right now."
    end

    # cached gem specification path, if one exists
    def gemspec_cached_path spec_file_name
      paths = Bundler.rubygems.spec_cache_dirs.map { |dir| File.join(dir, spec_file_name) }
      paths = paths.select {|path| File.file? path }
      paths.first
    end

    # return the specs in the bundler format as an index
    def specs(gem_names, source)
      use_full_index = !gem_names || @remote_uri.scheme == "file" || Bundler::Fetcher.disable_endpoint

      if !use_full_index
        index = fetch_dep_specs(gem_names, source)
        return index if index
        Bundler.ui.debug "Rubygems server at #{uri} does not support the dependency index," \
          "falling back on the full index of all specs."
      end

      # API errors mean we should treat this as a non-API source
      @use_api = false

      specs = Bundler::Retry.new("source fetch").attempts do
        fetch_all_remote_specs
      end

      Index.new do |index|
        specs[@remote_uri].each do |name, version, platform, dependencies|
          next if name == 'bundler'
          spec = nil
          if dependencies
            spec = EndpointSpecification.new(name, version, platform, dependencies)
          else
            spec = RemoteSpecification.new(name, version, platform, self)
          end
          spec.source = source
          spec.source_uri = @remote_uri
          index << spec
        end
      end
    rescue CertificateFailureError => e
      Bundler.ui.info "" if gem_names && use_api # newline after dots
      raise e
    end

    def use_api
      return @use_api if defined?(@use_api)

      if @remote_uri.scheme == "file" || Bundler::Fetcher.disable_endpoint
        @use_api = false
      else
        @use_api = true
      end
    end

    def inspect
      "#<#{self.class}:0x#{object_id} uri=#{uri}>"
    end

  private

    HTTP_ERRORS = [
      Timeout::Error, EOFError, SocketError,
      Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT, Errno::EAGAIN,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError,
      Net::HTTP::Persistent::Error
    ]

    def fetch(uri, counter = 0)
      raise HTTPError, "Too many redirects" if counter >= @redirect_limit

      begin
        Bundler.ui.debug "Fetching from: #{uri}"
        req = Net::HTTP::Get.new uri.request_uri
        req.basic_auth(uri.user, uri.password) if uri.user
        response = connection.request(uri, req)
      rescue OpenSSL::SSL::SSLError
        raise CertificateFailureError.new(uri)
      rescue *HTTP_ERRORS
        raise HTTPError, "Network error while fetching #{uri}"
      end

      case response
      when Net::HTTPRedirection
        Bundler.ui.debug("HTTP Redirection")
        new_uri = URI.parse(response["location"])
        if new_uri.host == uri.host
          new_uri.user = uri.user
          new_uri.password = uri.password
        end
        fetch(new_uri, counter + 1)
      when Net::HTTPSuccess
        Bundler.ui.debug("HTTP Success")
        response.body
      when Net::HTTPRequestEntityTooLarge
        raise FallbackError, response.body
      else
        raise HTTPError, "#{response.class}: #{response.body}"
      end
    end

    def dependency_api_uri(gem_names = [])
      url = "#{@remote_uri}api/v1/dependencies"
      url << "?gems=#{URI.encode(gem_names.join(","))}" if gem_names.any?
      URI.parse(url)
    end

    def fetch_dep_specs(names, source)
      index = Bundler::DepSpecs.new(source, @remote_uri).specs(names)
      index.size.zero? ? nil : index
    end

    # fetch from modern index: specs.4.8.gz
    def fetch_all_remote_specs
      Bundler.rubygems.sources = ["#{@remote_uri}"]
      Bundler.rubygems.fetch_all_remote_specs
    rescue Gem::RemoteFetcher::FetchError, OpenSSL::SSL::SSLError => e
      if e.message.match("certificate verify failed")
        raise CertificateFailureError.new(uri)
      else
        Bundler.ui.trace e
        raise HTTPError, "Could not fetch specs from #{uri}"
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

  end
end
