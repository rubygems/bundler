# frozen_string_literal: true
module Bundler
  module Plugin
    class << self
      @@command = {}
      @@after_install_hooks = []
      @@sources = {}

      def init
        # only a crude implementation for demo
        Dir.glob(plugin_root.join("*").join("plugin.rb")).each do |file|
          require file
        end
      rescue
      end

      def install(name, git_path)
        git_proxy = Source::Git::GitProxy.new(plugin_cache.join(name), git_path, "master")
        git_proxy.checkout
        git_proxy.copy_to(plugin_root.join(name))

        unless File.file? plugin_root.join(name).join("plugin.rb")
          raise "plugin.rb is not present in the repo"
        end

        Bundler.ui.info "Installed plugin #{name}"

      end

      def plugin_root
        Bundler.user_bundle_path.join("plugins")
      end

      def plugin_cache
        Bundler.user_cache.join("plugins")
      end

      def add_command(command, command_class)
        raise "Command already registered" if is_command? command

        @@command[command] = command_class
      end

      def is_command?(command)
        # TODO: check for inbuilt commands
        @@command.key? command
      end

      def exec(command, args = nil)
        cmd = @@command[command].new

        cmd.execute(args)
      end

      def register_after_install(&block)
        @@after_install_hooks << block
      end

      def post_install(gem)
        @@after_install_hooks.each do |cb|
          cb.call(gem)
        end
      end

      def add_source(name, cls)
        raise "Source already registered" if source? name

        @@sources[name] = cls
      end

      def source?(name)
        @@sources.key? name
      end

      def source(source_name, source)
        obj = @@sources[source_name].new

        Proc.new do |name, version|
          # This downloads the gem from source and returns the path
          obj.source_get(source, name, version)
        end
      end
    end

    class Base
      def self.command(command)
        # TODO: pass the class
        Plugin.add_command command, self
      end

      def self.add_hook(event, &block)
        if event == "post-install"
          Plugin.register_after_install( &block)
        end
      end

      def self.source(name)
        Plugin.add_source name, self
      end

      def execute(args)
      end
    end

  end
end
