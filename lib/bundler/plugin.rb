# frozen_string_literal: true

module Bundler
  class Plugin
    autoload :Dsl,        "bundler/plugin/dsl"
    autoload :Index,      "bundler/plugin/index"
    autoload :Installer,  "bundler/plugin/installer"
    autoload :SourceList, "bundler/plugin/source_list"

    class << self
      # Installs a new plugin by the given name
      #
      # @param [String] name the name of plugin to be installed
      # @param [Hash] options various parameters as described in description
      # @option options [String] :source rubygems source to fetch the plugin gem from
      # @option options [String] :version (optional) the version of the plugin to install
      def install(name, options)
        plugin_path = Pathname.new Installer.new.install(name, options)

        validate_plugin! plugin_path

        register_plugin name, plugin_path

        Bundler.ui.info "Installed plugin #{name}"
      rescue StandardError => e
        Bundler.rm_rf(plugin_path) if plugin_path
        Bundler.ui.error "Failed to install plugin #{name}: #{e.message}\n  #{e.backtrace.join("\n  ")}"
      end

      # Evaluates the Gemfile with a limited DSL and installs the plugins
      # specified by plugin method
      #
      # @param [Pathname] gemfile path
      def eval_gemfile(gemfile)
        definition = Dsl.evaluate(gemfile, nil, {})
        return unless definition.dependencies.any?

        plugins = Installer.new.install_definition(definition)

        plugins.each do |name, path|
          path = Pathname.new path
          validate_plugin! path
          register_plugin name, path
          Bundler.ui.info "Installed plugin #{name}"
        end
      end

      # The index object used to store the details about the plugin
      def index
        @index ||= Index.new
      end

      # The directory root to all plugin related data
      def root
        @root ||= Bundler.user_bundle_path.join("plugin")
      end

      # The cache directory for plugin stuffs
      def cache
        @cache ||= root.join("cache")
      end

    private

      # Checks if the gem is good to be a plugin
      #
      # At present it only checks whether it contains plugin.rb file
      #
      # @param [Pathname] plugin_path the path plugin is installed at
      #
      # @raise [Error] if plugin.rb file is not found
      def validate_plugin!(plugin_path)
        plugin_file = plugin_path.join("plugin.rb")
        raise "plugin.rb was not found in the plugin!" unless plugin_file.file?
      end

      # Runs the plugin.rb file, records the plugin actions it registers for and
      # then passes the data to index to be stored
      #
      # @param [String] name the name of the plugin
      # @param [Pathname] path the path where the plugin is installed at
      def register_plugin(name, path)
        require path.join("plugin.rb") # this shall latter be used to find the actions the plugin performs

        index.register_plugin name, path.to_s
      end
    end
  end
end
