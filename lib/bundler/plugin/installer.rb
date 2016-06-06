# frozen_string_literal: true

module Bundler
  # Handles the installation of plugin in appropriate directories.
  #
  # This class is supposed to be wrapper over the existing gem installation infra
  # but currently it itself handles everything as the Source's subclasses (e.g. Source::RubyGems)
  # are heavily dependent on the Gemfile.
  module Plugin
    class Installer
      autoload :Rubygems, "bundler/plugin/installer/rubygems"
      autoload :Git,      "bundler/plugin/installer/git"

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

      # Installs the plugin from Definition object created by limited parsing of
      # Gemfile searching for plugins to be installed
      #
      # @param [Definition] definiton object
      # @return [Hash] map of plugin names to thier paths
      def install_definition(definition)
        plugins = definition.dependencies.map(&:name)

        definition.resolve_remotely!
        specs = definition.specs

        paths = install_from_specs specs

        paths.select {|name, _| plugins.include? name }
      end

    private

      def install_git(name, options)
        uri = options.delete(:git)

        options[:name] = name
        options[:uri] = uri

        git_source = Git.new options
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
        rg_source = Rubygems.new "remotes" => source
        rg_source.remote!
        rg_source.dependency_names << name

        dep = Dependency.new name, version

        deps_proxies = [DepProxy.new(dep, GemHelpers.generic_local_platform)]
        idx = rg_source.specs

        specs = Resolver.resolve(deps_proxies, idx).materialize([dep])
        paths = install_from_specs specs

        paths[name]
      end

      # Installs the plugins and deps from the provided specs and returns map of
      # gems to their paths
      #
      # @param specs to install
      #
      # @return [Hash] map of names to path where the plugin was installed
      def install_from_specs(specs)
        paths = {}

        specs.each do |spec|
          spec.source.install spec

          paths[spec.name] = spec.full_gem_path
        end

        paths
      end
    end
  end
end
