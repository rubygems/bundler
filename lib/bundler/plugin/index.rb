# frozen_string_literal: true
module Bundler
  # This class keeps the index of which command, source or hook maps to which plugin
  class Plugin::Index
    def initialize(config)
      @config_file = config

      # These maps to their plugin names (not classes as in Plugin class)
      @commands = {}
      @post_install_hooks = []
      @sources = {}

      load_config
    end

    def load_config
      SharedHelpers.filesystem_access(config_file, :read) do
        valid_file = config_file && config_file.exist? && !config_file.size.zero?
        return unless valid_file
        require "bundler/psyched_yaml"
        config = YAML.load_file(@config_file)
        @commands = config[:commands]
        @post_install_hooks = config[:post_install_hooks]
        @sources = config[:sources]
      end
    end

    def save_config
      index = {
        :commands => @commands,
        :post_install_hooks => @post_install_hooks,
        :sources => @sources,
      }

      SharedHelpers.filesystem_access(@config_file) do |p|
        require "bundler/psyched_yaml"
        FileUtils.mkdir_p(p.dirname)
        File.open(p, "w") {|f| f.puts YAML.dump(index) }
      end
    end

    def config_file
      @config_file
    end

    # We keep track which command  or source belong to which plugin
    # and which all plugins declare a specific hook
    def add_plugin(plugin, commands, sources, post_install_hooks)
      raise "Command already registed" unless (commands.keys & @commands.keys).empty?
      raise "Source already registed" unless (sources.keys & @sources.keys).empty?

      commands.keys.each {|cmd| @commands[cmd] = plugin }
      sources.keys.each {|source| @sources[source] = plugin }
      @post_install_hooks << plugin
      save_config
    end

    def command?(command)
      @commands.key? command
    end

    # Return the plugin name to which the command belongs
    def command_plugin(command)
      @commands[command]
    end

    def source?(source)
      @sources.key? source
    end

    def source_plugin(source)
      @sources[source]
    end

    # Returns the array of plugin names to which declare the hook
    def post_install_hooks
      @post_install_hooks
    end
  end
end
