# forzen_string_literal: true
require "yaml"

module Bundler
  class Plugin::Index

    def initialize
      @plugin_sources = {}

      load_index
    end

    def load_index
      SharedHelpers.filesystem_access(index_file, :read) do |index_f|
        valid_file = index_f && index_f.exist? && !index_f.size.zero?
        return unless valid_file
        index = YAML.load_file(index_f)
        @plugin_sources = index[:plugin_sources]
      end
    end

    def save_index
      index = {
        :plugin_sources => @plugin_sources
      }

      SharedHelpers.filesystem_access(index_file) do |index_f|
        FileUtils.mkdir_p(index_f.dirname)
        File.open(index_f, "w") { |f| f.puts YAML.dump(index) }
      end
    end

    def register_plugin(name, path)
      @plugin_sources[name] = path

      save_index
    end

    def index_file
      Plugin.root.join("index")
    end
  end
end
