# frozen_string_literal: true

module Bundler
  module Plugin
    autoload :API,        "bundler/plugin/api"
    autoload :DSL,        "bundler/plugin/dsl"
    autoload :Index,      "bundler/plugin/index"
    autoload :Installer,  "bundler/plugin/installer"
    autoload :SourceList, "bundler/plugin/source_list"

    MalformattedPlugin = Class.new(PluginError)
    UndefinedCommandError = Class.new(PluginError)

    PLUGIN_FILE_NAME = "plugins.rb".freeze

    @commands = {}

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
      rescue PluginError => e
        Bundler.rm_rf(plugin_path) if plugin_path
        Bundler.ui.error "Failed to install plugin #{name}: #{e.message}\n  #{e.backtrace.join("\n  ")}"
      end

      # Evaluates the Gemfile with a limited DSL and installs the plugins
      # specified by plugin method
      #
      # @param [Pathname] gemfile path
      def eval_gemfile(gemfile)
        definition = DSL.evaluate(gemfile, nil, {})
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

      # To be called via the API to register to handle a command
      def add_command(command, cls)
        @commands[command] = cls
      end

      # Checks if any plugins handles the command
      def command?(command)
        !index.command_plugin(command).nil?
      end

      # To be called from Cli class to pass the command and argument to
      # approriate plugin class
      def exec_command(command, args)
        raise UndefinedCommandError, "Command #{command} not found" unless command? command

        load_plugin index.command_plugin(command) unless @commands.key? command

        @commands[command].new.exec(command, args)
      end

    private

      # Checks if the gem is good to be a plugin
      #
      # At present it only checks whether it contains plugins.rb file
      #
      # @param [Pathname] plugin_path the path plugin is installed at
      # @raise [Error] if plugins.rb file is not found
      def validate_plugin!(plugin_path)
        plugin_file = plugin_path.join(PLUGIN_FILE_NAME)
        raise MalformattedPlugin, "#{PLUGIN_FILE_NAME} was not found in the plugin!" unless plugin_file.file?
      end

      # Runs the plugins.rb file in an isolated namespace, records the plugin
      # actions it registers for and then passes the data to index to be stored.
      #
      # @param [String] name the name of the plugin
      # @param [Pathname] path the path where the plugin is installed at
      def register_plugin(name, path)
        commands = @commands

        @commands = {}

        begin
          load path.join(PLUGIN_FILE_NAME), true
        rescue StandardError => e
          raise MalformattedPlugin, "#{e.class}: #{e.message}"
        end

        index.register_plugin name, path.to_s, @commands.keys
      ensure
        @commands = commands
      end

      # Executes the plugins.rb file
      #
      # @param [String] name of the plugin
      def load_plugin(name)
        # Need to ensure before this that plugin root where the rest of gems
        # are installed to be on load path to support plugin deps. Currently not
        # done to avoid conflicts
        path = index.plugin_path(name)

        load path.join(PLUGIN_FILE_NAME)
      end
    end
  end
end
