require 'uri'
require 'net/http/persistent'

module Bundler
  class Fetcher
    REDIRECT_LIMIT = 5

    def initialize(remote_uri)
      @remote_uri = remote_uri
      @@connection ||= Net::HTTP::Persistent.new nil, :ENV
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
    def specs(gem_names, source, spec_fetch_map)
      index = Index.new

      fetch_remote_specs(gem_names)[@remote_uri].each do |name, version, platform|
        next if name == 'bundler'
        spec = RemoteSpecification.new(name, version, platform, self)
        spec.source = source
        spec_fetch_map[spec.full_name] = [spec, @remote_uri]
        index << spec
      end

      index
    end

    # fetch index
    def fetch_remote_specs(gem_names, full_dependency_list = [], last_spec_list = [])
      return fetch_all_remote_specs unless gem_names && @remote_uri.scheme != "file"

      query_list = gem_names - full_dependency_list
      Bundler.ui.debug "Query List: #{query_list.inspect}"
      return {@remote_uri => last_spec_list} if query_list.empty?

      Bundler.ui.info "Fetching dependency information from the API at #{@remote_uri}"
      spec_list, deps_list = fetch_dependency_remote_specs(query_list)
      returned_gems = spec_list.map {|spec| spec.first }.uniq

      fetch_remote_specs(deps_list, full_dependency_list + returned_gems, spec_list + last_spec_list)
    # fall back to the legacy index in the following cases
    # 1.) Gemcutter Endpoint doesn't return a 200
    # 2.) Marshal blob doesn't load properly
    rescue HTTPError, TypeError => e
      Bundler.ui.debug "Error #{e.class} from Gemcutter Dependency Endpoint API: #{e.message}"
      Bundler.ui.debug e.backtrace
      fetch_all_remote_specs
    end

  private

    def fetch(uri, counter = 0)
      raise HTTPError, "Too many redirects" if counter >= REDIRECT_LIMIT

      begin
        Bundler.ui.debug "Fetching from: #{uri}"
        response = @@connection.request(uri)
      rescue SocketError, Timeout
        raise Bundler::HTTPError, "Network error while fetching #{uri}"
      end

      case response
      when Net::HTTPRedirection
        Bundler.ui.debug("HTTP Redirection")
        uri = URI.parse(response["location"])
        fetch(uri, counter + 1)
      when Net::HTTPSuccess
        Bundler.ui.debug("HTTP Success")
        response.body
      else
        Bundler.ui.debug("HTTP Error")
        raise HTTPError
      end
    end

    # fetch from Gemcutter Dependency Endpoint API
    def fetch_dependency_remote_specs(gem_names)
      Bundler.ui.debug "Query Gemcutter Dependency Endpoint API: #{gem_names.join(' ')}"
      uri = URI.parse("#{@remote_uri}api/v1/dependencies?gems=#{gem_names.join(",")}")
      marshalled_deps = fetch(uri)
      gem_list = Marshal.load(marshalled_deps)

      spec_list = gem_list.map do |s|
        [s[:name], Gem::Version.new(s[:number]), s[:platform]]
      end
      deps_list = gem_list.map do |s|
        s[:dependencies].collect {|d| d.first }
      end.flatten.uniq

      [spec_list, deps_list]
    end

    # fetch from modern index: specs.4.8.gz
    def fetch_all_remote_specs
      Bundler.ui.info "Fetching source index for #{@remote_uri}"
      Bundler.ui.debug "Fetching modern index"
      Gem.sources = ["#{@remote_uri}"]
      spec_list = Hash.new { |h,k| h[k] = [] }
      begin
        # Fetch all specs, minus prerelease specs
        spec_list = Gem::SpecFetcher.new.list(true, false)
        # Then fetch the prerelease specs
        begin
          Gem::SpecFetcher.new.list(false, true).each {|k, v| spec_list[k] += v }
        rescue Gem::RemoteFetcher::FetchError
          Bundler.ui.warn "Could not fetch prerelease specs from #{@remote_uri}"
        end
      rescue Gem::RemoteFetcher::FetchError
        raise Bundler::HTTPError, "Could not reach #{@remote_uri}"
      end

      return spec_list
    end
  end
end
