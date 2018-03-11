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

      def install(names, options)
        version = options[:version] || [">= 0"]
        Bundler.settings.temporary(:lockfile_uses_separate_rubygems_sources => false, :disable_multisource => false) do
          sources = extract_sources_from_options!(options)
          source_list = prepare_source_list(sources, options)
          definition = create_definition(names, source_list, version)
          install_definition(definition)
        end
      end

      # Installs the plugin from Definition object created by limited parsing of
      # Gemfile searching for plugins to be installed
      #
      # @param [Definition] definition object
      # @return [Hash] map of names to their specs they are installed with
      def install_definition(definition)
        def definition.lock(*); end
        definition.resolve_remotely!
        specs = definition.specs

        install_from_specs specs
      end

    private

      def extract_sources_from_options!(options)
        sources = {}

        sources[:git] = options.delete(:git) if options[:git]
        sources[:file] = options.delete(:file) if options[:file]
        sources[:source] = options.delete(:source) if options[:source]

        sources
      end

      def prepare_source_list(sources, options)
        source_list = SourceList.new

        if sources[:git]
          source_list.add_git_source(options.merge("uri" => sources[:git]))
        end

        if sources[:file]
          file_uri = "file://#{URI.escape(sources[:file])}"
          source_list.add_git_source(options.merge("uri" => file_uri))
        end

        if sources[:source]
          source_list.add_rubygems_source("remotes" => sources[:source])
        end

        if sources.empty?
          sources = Bundler.rubygems.sources
          source_list.add_rubygems_source("remotes" => sources)
        end

        source_list
      end

      def create_definition(names, source_list, version)
        deps = names.map {|name| Dependency.new name, version }
        Definition.new(nil, deps, source_list, true)
      end

      # Installs the plugins and deps from the provided specs and returns map of
      # gems to their paths
      #
      # @param specs to install
      #
      # @return [Hash] map of names to the specs
      def install_from_specs(specs)
        paths = {}

        specs.each do |spec|
          spec.source.install spec

          paths[spec.name] = spec
        end

        paths
      end
    end
  end
end
