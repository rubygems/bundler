# frozen_string_literal: true

module Bundler
  module Plugin
    autoload :API,        "bundler/plugin/api"
    autoload :DSL,        "bundler/plugin/dsl"
    autoload :Index,      "bundler/plugin/index"
    autoload :Installer,  "bundler/plugin/installer"
    autoload :SourceList, "bundler/plugin/source_list"

    class MalformattedPlugin < PluginError; end
    class UndefinedCommandError < PluginError; end

    PLUGIN_FILE_NAME = "plugins.rb".freeze

  module_function

    @commands = {}
    @sources = {}

    # Installs a new plugin by the given name
    #
    # @param [Array<String>] names the name of plugin to be installed
    # @param [Hash] options various parameters as described in description
    # @option options [String] :source rubygems source to fetch the plugin gem from
    # @option options [String] :version (optional) the version of the plugin to install
    def install(names, options)
      paths = Installer.new.install(names, options)

      save_plugins paths
    rescue PluginError => e
      paths.values.map {|path| Bundler.rm_rf(path) } if paths
      Bundler.ui.error "Failed to install plugin #{name}: #{e.message}\n  #{e.backtrace.join("\n  ")}"
    end

    # Evaluates the Gemfile with a limited DSL and installs the plugins
    # specified by plugin method
    #
    # @param [Pathname] gemfile path
    def gemfile_install(gemfile = nil, &inline)
      if block_given?
        builder = DSL.new
        builder.instance_eval(&inline)
        definition = builder.to_definition(nil, true)
      else
        definition = DSL.evaluate(gemfile, nil, {})
      end
      return unless definition.dependencies.any?

      plugins = Installer.new.install_definition(definition)

      save_plugins plugins
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

    # currently only intended for specs
    #
    # @return [String, nil] installed path
    def installed?(plugin)
      Index.new.installed?(plugin)
    end

<<<<<<< 13f64fa210edbf92f3281e4055e88a37437d0486
    # Post installation processing and registering with index
    #
    # @param [Hash] plugins mapped to their installtion path
    def save_plugins(plugins)
      plugins.each do |name, path|
        path = Pathname.new path
        validate_plugin! path
        register_plugin name, path
        Bundler.ui.info "Installed plugin #{name}"
=======
      def add_source(source, cls)
        @sources[source] = cls
      end

      def source?(name)
        index.source? name
      end

      def source(name)
        load_plugin index.source_plugin name unless @sources.key? name

        @sources[name]
      end

    private

      # Checks if the gem is good to be a plugin
      #
      # At present it only checks whether it contains plugin.rb file
      #
      # @param [Pathname] plugin_path the path plugin is installed at
      # @raise [Error] if plugin.rb file is not found
      def validate_plugin!(plugin_path)
        plugin_file = plugin_path.join(PLUGIN_FILE_NAME)
        raise "#{PLUGIN_FILE_NAME} was not found in the plugin!" unless plugin_file.file?
>>>>>>> A base for source plugin
      end
    end

<<<<<<< 13f64fa210edbf92f3281e4055e88a37437d0486
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
=======
      # Runs the plugin.rb file in an isolated namespace, records the plugin
      # actions it registers for and then passes the data to index to be stored.
      #
      # @param [String] name the name of the plugin
      # @param [Pathname] path the path where the plugin is installed at
      def register_plugin(name, path)
        commands = @commands
        sources = @sources

        @commands = {}
        @sources = {}
>>>>>>> A base for source plugin

      @commands = {}

<<<<<<< 13f64fa210edbf92f3281e4055e88a37437d0486
      begin
        load path.join(PLUGIN_FILE_NAME), true
      rescue StandardError => e
        raise MalformattedPlugin, "#{e.class}: #{e.message}"
=======
        index.register_plugin name, path.to_s, @commands.keys, @sources.keys
      ensure
        @commands = commands
        @sources = sources
>>>>>>> A base for source plugin
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

    class << self
      private :load_plugin, :register_plugin, :save_plugins, :validate_plugin!
    end
  end
end
