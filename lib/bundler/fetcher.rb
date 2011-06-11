require 'uri'
require 'net/http/persistent'

module Bundler
  # Handles all the fetching with the rubygems server
  class Fetcher
    REDIRECT_LIMIT = 5

    class << self
      attr_accessor :disable_endpoint
    end

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

      fetch_remote_specs(gem_names)[@remote_uri].each do |name, version, platform, dependencies|
        next if name == 'bundler'
        spec = nil
        if dependencies
          spec = EndpointSpecification.new(name, version, platform, dependencies)
        else
          spec = RemoteSpecification.new(name, version, platform, self)
        end
        spec.source = source
        spec_fetch_map[spec.full_name] = [spec, @remote_uri]
        index << spec
      end

      index
    end

    # fetch index
    def fetch_remote_specs(gem_names, full_dependency_list = [], last_spec_list = [])
      return fetch_all_remote_specs if !gem_names || @remote_uri.scheme == "file" || Bundler::Fetcher.disable_endpoint

      query_list = gem_names - full_dependency_list
      # only display the message on the first run
      if full_dependency_list.empty?
        Bundler.ui.info "Fetching dependency information from the API at #{@remote_uri}", false
      else
        Bundler.ui.info ".", false
      end

      Bundler.ui.debug "Query List: #{query_list.inspect}"
      if query_list.empty?
        Bundler.ui.info "\n"
        return {@remote_uri => last_spec_list}
      end

      spec_list, deps_list = fetch_dependency_remote_specs(query_list)
      returned_gems = spec_list.map {|spec| spec.first }.uniq

      fetch_remote_specs(deps_list, full_dependency_list + returned_gems, spec_list + last_spec_list)
    # fall back to the legacy index in the following cases
    # 1.) Gemcutter Endpoint doesn't return a 200
    # 2.) Marshal blob doesn't load properly
    rescue HTTPError, TypeError => e
      Bundler.ui.info "\nError using the API"
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
        new_uri = URI.parse(response["location"])
        new_uri.user = uri.user
        new_uri.password = uri.password
        fetch(new_uri, counter + 1)
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
      deps_list = []

      spec_list = gem_list.map do |s|
        dependencies = s[:dependencies].map do |d|
          name, requirement = d
          dep = Gem::Dependency.new(name, requirement.split(", "))

          deps_list << dep.name

          dep
        end

        [s[:name], Gem::Version.new(s[:number]), s[:platform], dependencies]
      end

      [spec_list, deps_list.uniq]
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
