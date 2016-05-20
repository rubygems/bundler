#frozen_string_literal: true

module Bundler
  class Plugin

    class << self

      def install(name, options)
        require "bundler/plugin/installer.rb"

        source = options[:source] || raise(ArgumentError, "You need to provide the source")
        version = options[:version] || [">= 0"]

        plugin_path = Installer.install(name, source, version)

        puts plugin_path

        Bundler.ui.info "Installed plugin #{name}"
      rescue StandardError => e
        Bundler.ui.error "Failed to install plugin #{name}: #{e.message}\n  #{e.backtrace.join("\n  ")}"
        Bundler.ui.trace e
      end


      def root
        @root ||= Bundler.user_bundle_path.join("plugin")
      end

      def cache
        @cache ||= root.join "cache"
      end
    end
  end
end
