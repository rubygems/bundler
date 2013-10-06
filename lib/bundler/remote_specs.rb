module Bundler
  class RemoteSpecs

    def initialize(source, source_uri)
      @source, @source_uri = source, source_uri
    end

    def specs_index
      data = fetch_remote_specs(gem_names)[@remote_uri]

      Index.build do |index|
        data.each do |name, version, platform, dependencies|
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

      remote_specs = Bundler::Retry.new("dependency api").attempts do
        fetch_dependency_remote_specs(query_list)
      end

      spec_list, deps_list = remote_specs
      returned_gems = spec_list.map {|spec| spec.first }.uniq
      fetch_remote_specs(deps_list, full_dependency_list + returned_gems, spec_list + last_spec_list)
    rescue HTTPError, MarshalError, GemspecError => e
      Bundler.ui.info "" unless Bundler.ui.debug? # new line now that the dots are over
      Bundler.ui.debug "could not fetch from the dependency API, trying the full index"
      @use_api = false
      return nil
    end

    # fetch from Gemcutter Dependency Endpoint API
    def fetch_dependency_remote_specs(gem_names)
      Bundler.ui.debug "Query Gemcutter Dependency Endpoint API: #{gem_names.join(',')}"
      marshalled_deps = Bundler::Fetcher.get dependency_api_uri(gem_names)
      gem_list = Bundler.load_marshal(marshalled_deps)
      deps_list = []

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
      url = "#{@remote_uri}api/v1/dependencies"
      url << "?gems=#{URI.encode(gem_names.join(","))}" if gem_names.any?
      URI.parse(url)
    end

