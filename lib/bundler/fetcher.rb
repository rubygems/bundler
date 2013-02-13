require 'bundler/vendored_persistent'

module Bundler
  # This is the error raised if OpenSSL fails the cert verification
  class CertificateFailureError < HTTPError
    def initialize(message = nil)
      @message = message
      @message ||= "\nCould not verify the SSL certificate for " \
        "#{@remote_uri}. Either you don't have the CA certificates needed to " \
        "verify it, or you are experiencing a man-in-the-middle attack. To " \
        "connect without using SSL, edit your Gemfile sources to and change " \
        "'https' to 'http'."
    end
  end

  # Handles all the fetching with the rubygems server
  class Fetcher
    REDIRECT_LIMIT = 5
    # how long to wait for each gemcutter API call
    API_TIMEOUT    = 10

    class << self
      attr_accessor :disable_endpoint

      @@spec_fetch_map ||= {}

      def fetch(spec)
        spec, uri = @@spec_fetch_map[spec.full_name]
        if spec
          path = download_gem_from_uri(spec, uri)
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
    end

    def initialize(remote_uri)
      @remote_uri = remote_uri
      @public_uri = remote_uri.dup
      @public_uri.user, @public_uri.password = nil, nil # don't print these
      @connection ||= Net::HTTP::Persistent.new 'bundler', :ENV
      @connection.read_timeout = API_TIMEOUT

      Socket.do_not_reverse_lookup = true
    end

    # fetch a gem specification
    def fetch_spec(spec)
      spec = spec - [nil, 'ruby', '']
      spec_file_name = "#{spec.join '-'}.gemspec.rz"

      uri = URI.parse("#{@remote_uri}#{Gem::MARSHAL_SPEC_DIR}#{spec_file_name}")

      spec_rz = (uri.scheme == "file") ? Gem.read_binary(uri.path) : fetch(uri)
      Marshal.load Gem.inflate(spec_rz)
    end

    # return the specs in the bundler format as an index
    def specs(gem_names, source)
      index = Index.new

      specs = nil

      if !gem_names || !use_api
        Bundler.ui.info "Fetching source index from #{@public_uri}"
        specs = fetch_all_remote_specs
      else
        Bundler.ui.info "Fetching gem metadata from #{@public_uri}", Bundler.ui.debug?
        begin
          specs = fetch_remote_specs(gem_names)
        # fall back to the legacy index in the following cases
        # 1. Gemcutter Endpoint doesn't return a 200
        # 2,3. Marshal blob doesn't load properly
        # 4. One of the YAML gemspecs has the Syck::DefaultKey problem
        rescue HTTPError, ArgumentError, TypeError, GemspecError => e
          # API errors mean we should treat this as a non-API source
          @use_api = false

          # new line now that the dots are over
          Bundler.ui.info "" unless Bundler.ui.debug?

          Bundler.ui.debug "Error during API request. #{e.class}: #{e.message}"
          Bundler.ui.debug e.backtrace.join("  ")

          Bundler.ui.info "Fetching full source index from #{@public_uri}"
          specs = fetch_all_remote_specs
        else
          # new line now that the dots are over
          Bundler.ui.info "" unless Bundler.ui.debug?
        end
      end

      specs[@remote_uri].each do |name, version, platform, dependencies|
        next if name == 'bundler'
        spec = nil
        if dependencies
          spec = EndpointSpecification.new(name, version, platform, dependencies)
        else
          spec = RemoteSpecification.new(name, version, platform, self)
        end
        spec.source = source
        @@spec_fetch_map[spec.full_name] = [spec, @remote_uri]
        index << spec
      end

      index
    rescue OpenSSL::SSL::SSLError
      raise CertificateFailureError.new
    end

    # fetch index
    def fetch_remote_specs(gem_names, full_dependency_list = [], last_spec_list = [])
      query_list = gem_names - full_dependency_list

      # only display the message on the first run
      if Bundler.ui.debug?
        Bundler.ui.debug "Query List: #{query_list.inspect}"
      else
        Bundler.ui.info ".", false
      end

      return {@remote_uri => last_spec_list} if query_list.empty?

      spec_list, deps_list = fetch_dependency_remote_specs(query_list)
      returned_gems = spec_list.map {|spec| spec.first }.uniq

      fetch_remote_specs(deps_list, full_dependency_list + returned_gems, spec_list + last_spec_list)
    end

    def use_api
      return @use_api if defined?(@use_api)

      if @remote_uri.scheme == "file" || Bundler::Fetcher.disable_endpoint
        @use_api = false
      elsif fetch(dependency_api_uri)
        @use_api = true
      end
    rescue HTTPError
      @use_api = false
    end

    def inspect
      "#<#{self.class}:0x#{object_id} uri=#{@public_uri.to_s}>"
    end

  private

    def fetch(uri, counter = 0)
      raise HTTPError, "Too many redirects" if counter >= REDIRECT_LIMIT

      begin
        Bundler.ui.debug "Fetching from: #{uri}"
        response = @connection.request(uri)
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ETIMEDOUT,
             EOFError, SocketError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
             Errno::EAGAIN, Net::HTTP::Persistent::Error, Net::ProtocolError
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
      else
        Bundler.ui.debug("HTTP Error")
        raise HTTPError, "Don't know how to process #{response.class}"
      end
    end

    def dependency_api_uri(gem_names = [])
      url = "#{@remote_uri}api/v1/dependencies"
      url << "?gems=#{URI.encode(gem_names.join(","))}" if gem_names.any?
      URI.parse(url)
    end

    # fetch from Gemcutter Dependency Endpoint API
    def fetch_dependency_remote_specs(gem_names)
      Bundler.ui.debug "Query Gemcutter Dependency Endpoint API: #{gem_names.join(',')}"
      marshalled_deps = fetch dependency_api_uri(gem_names)
      gem_list = Marshal.load(marshalled_deps)
      deps_list = []

      spec_list = gem_list.map do |s|
        dependencies = s[:dependencies].map do |d|
          begin
            name, requirement = d
            dep = Gem::Dependency.new(name, requirement.split(", "))
          rescue ArgumentError => e
            if e.message.include?('Ill-formed requirement ["#<YAML::Syck::DefaultKey')
              puts # we shouldn't print the error message on the "fetching info" status line
              raise GemspecError,
                "Unfortunately, the gem #{s[:name]} (#{s[:number]}) has an invalid gemspec. \n" \
                "Please ask the gem author to yank the bad version to fix this issue. For \n" \
                "more information, see http://bit.ly/syck-defaultkey."
            else
              raise e
            end
          end

          deps_list << dep.name

          dep
        end

        [s[:name], Gem::Version.new(s[:number]), s[:platform], dependencies]
      end

      [spec_list, deps_list.uniq]
    end

    # fetch from modern index: specs.4.8.gz
    def fetch_all_remote_specs
      Bundler.rubygems.sources = ["#{@remote_uri}"]
      Bundler.rubygems.fetch_all_remote_specs
    rescue Gem::RemoteFetcher::FetchError => e
      if e.message.match("certificate verify failed")
        raise CertificateFailureError.new
      else
        raise HTTPError, "Could not fetch specs from #{@public_uri}"
      end
    end

  end
end
