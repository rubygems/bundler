# frozen_string_literal: true

module Bundler
  # Manages which plugins are installed and their sources. This also is supposed to map
  # which plugin does what (currently the features are not implemented so this class is
  # now a stub class).
  module Plugin
    class Index
      class CommandConflict < PluginError
        def initialize(plugin, commands)
          msg = "Command(s) `#{commands.join("`, `")}` declared by #{plugin} are already registered."
          super msg
        end
      end

      class SourceConflict < PluginError
        def initialize(plugin, sources)
          msg = "Source(s) `#{sources.join("`, `")}` declared by #{plugin} are already registered."
          super msg
        end
      end

      def initialize
        @plugin_paths = {}
        @commands = {}
        @sources = {}

        load_index
      end

      # This function is to be called when a new plugin is installed. This function shall add
      # the functions of the plugin to existing maps and also the name to source location.
      #
      # @param [String] name of the plugin to be registered
      # @param [String] path where the plugin is installed
      # @param [Array<String>] commands that are handled by the plugin
      def register_plugin(name, path, commands, sources)
        common = commands & @commands.keys
        raise CommandConflict.new(name, common) unless common.empty?
        commands.each {|c| @commands[c] = name }

        common = sources & @sources.keys
        raise SourceConflict.new(name, common) unless common.empty?
        sources.each {|k| @sources[k] = name }

        @plugin_paths[name] = path
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

      def installed?(name)
        @plugin_paths[name]
      end

      def source?(source)
        @sources.key? source
      end

      def source_plugin(name)
        @sources[name]
      end

    private

      # Reads the index file from the directory and initializes the instance variables.
      def load_index
        SharedHelpers.filesystem_access(index_file, :read) do |index_f|
          valid_file = index_f && index_f.exist? && !index_f.size.zero?
          break unless valid_file
          data = index_f.read
          require "bundler/yaml_serializer"
          index = YAMLSerializer.load(data)
          @plugin_paths = index["plugin_paths"] || {}
          @commands = index["commands"] || {}
          @sources = index["sources"] || {}
        end
      end

      # Should be called when any of the instance variables change. Stores the instance
      # variables in YAML format. (The instance variables are supposed to be only String key value pairs)
      def save_index
        index = {
          "plugin_paths" => @plugin_paths,
          "commands" => @commands,
          "sources" => @sources,
        }

        require "bundler/yaml_serializer"
        SharedHelpers.filesystem_access(index_file) do |index_f|
          FileUtils.mkdir_p(index_f.dirname)
          File.open(index_f, "w") {|f| f.puts YAMLSerializer.dump(index) }
        end
      end
    end
  end
end
