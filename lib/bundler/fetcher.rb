require 'uri'
require 'net/http/persistent'

module Bundler
  class Fetcher
    def initialize(remote_uri)
      @remote_uri = remote_uri
      @@connection ||= Net::HTTP::Persistent.new
    end

    # fetch a gem specification
    def fetch_spec(spec)
      spec = spec - [nil, 'ruby', '']
      spec_file_name = "#{spec.join '-'}.gemspec.rz"

      uri = URI.parse("#{@remote_uri}#{Gem::MARSHAL_SPEC_DIR}#{spec_file_name}")
      Bundler.ui.debug "Fetching spec from: #{uri}"

      spec_rz = (uri.scheme == "file") ? Gem.read_binary(uri.path) : fetch(uri)
      Marshal.load Gem.inflate(spec_rz)
    end

    # fetch index
    def fetch_remote_specs(gem_names, full_dependency_list = [], last_spec_list = [], &blk)
      return fetch_all_remote_specs(&blk) unless gem_names && @remote_uri.scheme != "file"

      query_list = gem_names - full_dependency_list
      Bundler.ui.debug "Query List: #{query_list.inspect}"
      return {@remote_uri => last_spec_list}.each(&blk) if query_list.empty?

      spec_list, deps_list = fetch_dependency_remote_specs(query_list, &blk)
      returned_gems = spec_list.map {|spec| spec.first }.uniq

      fetch_remote_specs(deps_list, full_dependency_list + returned_gems, spec_list + last_spec_list, &blk)
    # fall back to the legacy index in the following cases
    # 1.) Gemcutter Endpoint doesn't return a 200
    # 2.) Marshal blob doesn't load properly
    rescue OpenURI::HTTPError, TypeError
      fetch_all_remote_specs(&blk)
    end

  private

    def fetch(uri)
      @@connection.request(uri).body
    end

    # fetch from Gemcutter Dependency Endpoint API
    def fetch_dependency_remote_specs(gem_names, &blk)
      marshalled_deps = @@connection.request("#{@remote_uri}api/v1/dependencies?gems=#{gem_names.join(",")}").body
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
    def fetch_all_remote_specs(&blk)
      Gem.sources = ["#{@remote_uri}"]
      begin
        # Fetch all specs, minus prerelease specs
        Gem::SpecFetcher.new.list(true, false).each(&blk)
        # Then fetch the prerelease specs
        begin
          Gem::SpecFetcher.new.list(false, true).each(&blk)
        rescue Gem::RemoteFetcher::FetchError
          Bundler.ui.warn "Could not fetch prerelease specs from #{self}"
        end
      rescue Gem::RemoteFetcher::FetchError
        Bundler.ui.warn "Could not reach #{self}"
      end
    end
  end
end
