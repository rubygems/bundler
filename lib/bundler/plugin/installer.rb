# frozen_string_literal: true

module Bundler
  # Handles the installation of plugin in appropriate directories.
  #
  # This class is supposed to be wrapper over the existing gem installation infra
  # but currently it itself handles everything as the Source's subclasses (e.g. Source::RubyGems)
  # are heavily dependent on the Gemfile.
  #
  # @todo: Remove the dependencies of Source's subclasses and try to use the Bundler sources directly. This will reduce the redundancies.
  class Plugin::Installer
    def install(name, options)
      if options[:git]
        install_git(name, options)
      elsif options[:source]
        source = options[:source]
        version = options[:version] || [">= 0"]

        install_rubygems(name, source, version)
      else
        raise(ArgumentError, "You need to provide the source")
      end
    end

    def install_definition(definition)
      plugins = definition.dependencies.map(&:name)

      definition.resolve_remotely!
      specs = definition.specs

      paths = install_from_spec specs

      paths.select {|name, _| plugins.include? name}
    end

  private

    def install_git(name, options)
      uri = options.delete(:git)

      options[:name] = name
      options[:uri] = uri
      options[:plugin] = true

      git_source = Source::Git.new options
      git_source.remote!

      git_source.install(git_source.specs.first)

      git_source.path
    end

    # Installs the plugin from rubygems source and returns the path where the
    # plugin was installed
    #
    # @param [String] name of the plugin gem to search in the source
    # @param [String] source the rubygems URL to resolve the gem
    # @param [Array, String] version (optional) of the gem to install
    #
    # @return [String] the path where the plugin was installed
    def install_rubygems(name, source, version = [">= 0"])
      rg_source = Source::Rubygems.new "remotes" => source, :plugin => true
      rg_source.remote!
      rg_source.dependency_names << name

      dep = Dependency.new name, version

      deps_proxies = [DepProxy.new(dep, GemHelpers.generic_local_platform)]
      idx = rg_source.specs

      specs = Resolver.resolve(deps_proxies, idx).materialize([dep])
      paths = install_from_spec specs

      paths[name]
    end

    # Installs the plugin from the provided spec and returns the path where the
    # plugin was installed.
    #
    # @param spec to fetch and install
    # @raise [ArgumentError] if the spec object has no remote set
    #
    # @return [String] the path where the plugin was installed
    def install_from_spec(specs)
      paths = {}

      specs.each do |spec|
        next if spec.name == "bundler"

        spec.source.install spec

        paths[spec.name] = spec.full_gem_path
      end

      paths
    end
  end
end
