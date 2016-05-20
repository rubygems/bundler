#frozen_string_literal: true

module Bundler
  class Plugin
    autoload :Index, "bundler/plugin/index"

    class << self

      def install(name, options)
        require "bundler/plugin/installer.rb"

        source = options[:source] || raise(ArgumentError, "You need to provide the source")
        version = options[:version] || [">= 0"]

        plugin_path = Pathname.new Installer.install(name, source, version)

        validate_plugin! plugin_path

        register_plugin name, plugin_path

        Bundler.ui.info "Installed plugin #{name}"
      rescue StandardError => e
        Bundler.rm_rf(plugin_path) if plugin_path
        Bundler.ui.error "Failed to install plugin #{name}: #{e.message}\n  #{e.backtrace.join("\n  ")}"
      end

      def validate_plugin! plugin_path
        unless File.file? plugin_path.join("plugin.rb")
          raise "plugin.rb was not found in the plugin gem!"
        end
      end

      def register_plugin name, path
        index.register_plugin name, path
      end

      def index
        @index ||= Index.new
      end

      def root
        @root ||= Bundler.user_bundle_path.join("plugin")
      end

      def cache
        @cache ||= root.join("cache")
      end
    end
  end
end
