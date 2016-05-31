# frozen_string_literal: true
require "yaml"

module Bundler
  # Manages which plugins are installed and their sources. This also is supposed to map
  # which plugin does what (currently the features are not implemented so this class is
  # now a stub class).
  class Plugin::Index
    def initialize
      @plugin_paths = {}
      @commands = {}

      load_index
    end

    # This function is to be called when a new plugin is installed. This function shall add
    # the functions of the plugin to existing maps and also the name to source location.
    #
    # @param [String] name of the plugin to be registered
    # @param [String] path where the plugin is installed
    # @param [Array<String>] commands that are handled by the plugin
    def register_plugin(name, path, commands)
      @plugin_paths[name] = path

      common = commands & @commands.keys
      raise "Command(s) #{common.join(", ")} are already registered" if common.any?
      commands.each {|c| @commands[c] = name }

      save_index
    end

    # Path where the index file is stored
    def index_file
      Plugin.root.join("index")
    end

    def plugin_path(name)
      Pathname.new @plugin_paths[name]
    end

    # Fetch the name of plugin handling the command
    def command_plugin(command)
      @commands[command]
    end

  private

    # Reads the index file from the directory and initializes the instance variables.
    def load_index
      SharedHelpers.filesystem_access(index_file, :read) do |index_f|
        valid_file = index_f && index_f.exist? && !index_f.size.zero?
        break unless valid_file
        index = YAML.load_file(index_f)
        @plugin_paths = index["plugin_paths"] || {}
        @commands = index["commands"] || {}
      end
    end

    # Should be called when any of the instance variables change. Stores the instance
    # variables in YAML format. (The instance variables are supposed to be only String key value pairs)
    def save_index
      index = {
        "plugin_paths" => @plugin_paths,
        "commands" => @commands,
      }

      SharedHelpers.filesystem_access(index_file) do |index_f|
        FileUtils.mkdir_p(index_f.dirname)
        File.open(index_f, "w") {|f| f.puts YAML.dump(index) }
      end
    end
  end
end
