# frozen_string_literal: true
module Bundler
  module Plugin
    class << self
      @@command = Hash.new

      def init
        # Just a crude implementation for demo
        Dir.glob(plugin_root.join("*").join("plugin.rb")).each do |file|
          require file
        end
      end

      def install(name, git_path)
        git_proxy = Source::Git::GitProxy.new(plugin_root.join(name), git_path, "master")
        git_proxy.checkout
      end

      def plugin_root
        Bundler.user_bundle_path.join("plugin")
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
    end

    class Base
      def self.command(command)
        # TODO: pass the class
        Plugin.add_command command, self
      end

      def execute(args)
      end
    end

  end
end
