# frozen_string_literal: true
module Bundler
  module Plugin
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
