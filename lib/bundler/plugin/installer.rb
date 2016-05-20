#frozen_string_literal: true

module Bundler
  class Plugin::Installer

    # Installs the plugin and returns the path where the plugin was installed
    def self.install(name, source, version = nil)
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


    # Installs the plugin from the provided spec and returns the path where the plugin was installed
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

  end
end
