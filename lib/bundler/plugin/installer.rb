#frozen_string_literal: true

module Bundler
  # Handles the installation of plugin in appropriate directories.
  #
  # This class is supposed to be wrapper over the existing gem installation infra
  # but currently it itself handles everything as the Source's subclasses (e.g. Source::RubyGems)
  # are heavily dependent on the Gemfile.
  #
  # @todo: Remove the dependencies of Source's subclasses and try to use the Bundler sources directly. This will reduce the redundancies.
  class Plugin::Installer

    def self.install(name, options)
      if options[:git]
        #uri = options[:git]
        #revision = options[:ref] || options[:branch] || "master"

        install_git(name, options)
      elsif options[:source]
        source = options[:source]
        version = options[:version] || [">= 0"]

        install_rubygems(name, source, version)
      else
        raise(ArgumentError, "You need to provide the source")
      end
    end

    def self.install_git(name, options)
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
    def self.install_rubygems(name, source, version = [">= 0"])
      rg_source = Source::Rubygems.new "remotes" => source, :ignore_app_cache => true
      rg_source.remote!
      rg_source.dependency_names << name

      dep = Dependency.new name, version

      deps_proxies = [DepProxy.new(dep, GemHelpers.generic_local_platform)]
      idx = rg_source.specs

      specs = Resolver.resolve(deps_proxies, idx).materialize([dep])

      raise InstallError, "Plugin dependencies are not supported currently" unless specs.size == 1

      install_from_spec specs.first
    end


    # Installs the plugin from the provided spec and returns the path where the
    # plugin was installed.
    #
    # @param spec to fetch and install
    # @raise [ArgumentError] if the spec object has no remote set
    #
    # @return [String] the path where the plugin was installed
    def self.install_from_spec(spec)
      raise ArgumentError, "Spec #{spec.name} doesn't have remote set" unless spec.remote

      uri = spec.remote.uri
      spec.fetch_platform

      download_path = Plugin.cache

      path = Bundler.rubygems.download_gem(spec, uri, download_path)

      Bundler.rubygems.preserve_paths do
        Bundler::RubyGemsGemInstaller.new(
          path,
          :install_dir         => Plugin.root.to_s,
          :ignore_dependencies => true,
          :wrappers            => true,
          :env_shebang         => true

        ).install.full_gem_path
      end
    end

    def self.base_name uri
      File.basename(uri.sub(%r{^(\w+://)?([^/:]+:)?(//\w*/)?(\w*/)*}, ""), ".git")
    end

    def self.uri_hash uri
      if uri =~ %r{^\w+://(\w+@)?}
        # Downcase the domain component of the URI
        # and strip off a trailing slash, if one is present
        input = URI.parse(uri).normalize.to_s.sub(%r{/$}, "")
      else
        # If there is no URI scheme, assume it is an ssh/git URI
        input = uri
      end
      Digest::SHA1.hexdigest(input)
    end
  end
end
