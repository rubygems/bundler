require 'uri'
require 'net/http/persistent'

module Bundler
  # Handles all the fetching with the rubygems server
  class Fetcher
    REDIRECT_LIMIT = 5

    attr_reader :has_api

    class << self
      attr_accessor :disable_endpoint

      @@spec_fetch_map ||= {}

      def fetch(spec)
        spec, uri = @@spec_fetch_map[spec.full_name]
        if spec
          path = download_gem_from_uri(spec, uri)
          s = Bundler.rubygems.spec_from_gem(path)
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
      @has_api    = true # will be set to false if the rubygems index is ever fetched
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
    def specs(gem_names, source)
      index = Index.new

      if !gem_names || @remote_uri.scheme == "file" || Bundler::Fetcher.disable_endpoint
        Bundler.ui.info "Fetching source index from #{strip_user_pass_from_uri(@remote_uri)}"
        specs = fetch_all_remote_specs
      else
        Bundler.ui.info "Fetching gem metadata from #{strip_user_pass_from_uri(@remote_uri)}", Bundler.ui.debug?
        begin
          specs = fetch_remote_specs(gem_names)
        # fall back to the legacy index in the following cases
        # 1. Gemcutter Endpoint doesn't return a 200
        # 2. Marshal blob doesn't load properly
        # 3. One of the YAML gemspecs has the Syck::DefaultKey problem
        rescue HTTPError, TypeError => e
          # new line now that the dots are over
          Bundler.ui.info "" unless Bundler.ui.debug?

          if @remote_uri.to_s.include?("rubygems.org")
            Bundler.ui.info "Error #{e.class} during request to dependency API"
          end
          Bundler.ui.debug e.message
          Bundler.ui.debug e.backtrace

          Bundler.ui.info "Fetching full source index from #{strip_user_pass_from_uri(@remote_uri)}"
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

  private

    def fetch(uri, counter = 0)
      raise HTTPError, "Too many redirects" if counter >= REDIRECT_LIMIT

      begin
        Bundler.ui.debug "Fetching from: #{uri}"
        response = @@connection.request(uri)
      rescue SocketError, Timeout::Error, Net::HTTP::Persistent::Error
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
          begin
            name, requirement = d
            dep = Gem::Dependency.new(name, requirement.split(", "))
          rescue ArgumentError => e
            if e.message.include?('Illformed requirement ["#<YAML::Syck::DefaultKey')
              puts # we shouldn't print the error message on the "fetching info" status line
              raise GemspecError, %{Unfortunately, the gem #{s[:name]} (#{s[:number]}) } +
                %{has an invalid gemspec. As a result, Bundler cannot install this Gemfile. } +
                %{Please ask the gem author to yank the bad version to fix this issue. For } +
                %{more information, see http://bit.ly/syck-defaultkey.}
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
      @has_api = false
      Gem.sources = ["#{@remote_uri}"]
      spec_list = Hash.new { |h,k| h[k] = [] }
      begin
        # Fetch all specs, minus prerelease specs
        spec_list = Gem::SpecFetcher.new.list(true, false)
        # Then fetch the prerelease specs
        begin
          Gem::SpecFetcher.new.list(false, true).each {|k, v| spec_list[k] += v }
        rescue Gem::RemoteFetcher::FetchError
          Bundler.ui.debug "Could not fetch prerelease specs from #{strip_user_pass_from_uri(@remote_uri)}"
        end
      rescue Gem::RemoteFetcher::FetchError
        raise Bundler::HTTPError, "Could not reach #{strip_user_pass_from_uri(@remote_uri)}"
      end

      return spec_list
    end

    def strip_user_pass_from_uri(uri)
      uri_dup = uri.dup
      uri_dup.user = "****" if uri_dup.user
      uri_dup.password = "****" if uri_dup.password

      uri_dup
    end
  end
end
