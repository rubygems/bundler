# frozen_string_literal: true
module Bundler
  class Plugin
    autoload :Index, "bundler/plugin/index"
    autoload :Base, "bundler/plugin/base"

    @commands = {}             # The map of loaded commands
    @post_install_hooks = []   # Array of blocks
    @sources = {}              # The map of loaded sources

    class << self
      # Installs a plugin and registers it with the index
      def install(name, git_path)
        git_proxy = Source::Git::GitProxy.new(plugin_cache.join(name), git_path, "master")
        git_proxy.checkout

        plugin_path = plugin_root.join(name)
        git_proxy.copy_to(plugin_path)

        unless File.file? plugin_path.join("plugin.rb")
          raise "plugin.rb is not present in the repo"
        end

        register_plugin name, plugin_path

        Bundler.ui.info "Installed plugin #{name}"
      rescue StandardError => e
        Bundler.rm_rf(plugin_root.join(name))
        Bundler.ui.info "Failed to installed plugin #{name}: #{e.message}"
      end

      # Saves the current state
      # Runs the plugin.rb
      # Passes the registerd commands to index
      # Restores the state
      def register_plugin(name, path)
        commands = @commands
        sources = @sources
        post_install_hooks = @post_install_hooks

        @commands = {}
        @post_install_hooks = []
        @sources = {}

        require path.join("plugin.rb")

        index.add_plugin name, @commands, @sources, @post_install_hooks
      ensure
        @commands = commands
        @post_install_hooks = post_install_hooks
        @sources = sources
      end

      # The ondemand loading of plugins
      def load_plugin(name)
        require plugin_root.join(name).join("plugin.rb")
      end

      def index
        @index ||= Index.new(plugin_config_file)
      end

      # Directory where plugins will be stored
      def plugin_root
        Bundler.user_bundle_path.join("plugins")
      end

      # The config file for activated plugins
      def plugin_config_file
        Bundler.user_bundle_path.join("plugin")
      end

      # Cache to store the downloaded plugins
      def plugin_cache
        Bundler.user_cache.join("plugins")
      end

      def add_command(command, command_class)
        @commands[command] = command_class
      end

      def command?(command)
        index.command? command
      end

      def exec(command, *args)
        raise "Unknown command" unless index.command? command

        load_plugin index.command_plugin(command) unless @commands.key? command

        cmd = @commands[command].new
        cmd.execute(command, args)
      end

      def register_post_install(&block)
        @post_install_hooks << block
      end

      def post_install(gem)
        if @post_install_hooks.length != index.post_install_hooks.length
          @post_install_hooks = []
          index.post_install_hooks.each {|p| load_plugin p }
        end

        @post_install_hooks.each do |cb|
          cb.call(gem)
        end
      end

      def add_source(name, cls)
        @sources[name] = cls
      end

      def source?(name)
        index.source? name
      end

      # Returns a block to be excuted with the gem name and version
      # and the plugin will fetch the gem to a local directory
      # and will return the path
      #
      # A workaround for demo. The real one will return a object of
      # class similar to Source::Git, maybe Source::Plugin with with the rest
      # of core infra can interact
      def source(source_name, source)
        raise "Unknown source" unless index.source? source_name

        load_plugin index.source_plugin(source_name) unless @sources.key? source_name

        obj = @sources[source_name].new

        proc do |name, version|
          # This downloads the gem from source and returns the path
          obj.source_get(source, name, version)
        end
      end
    end
  end
end
