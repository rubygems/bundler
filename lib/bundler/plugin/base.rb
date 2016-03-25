# frozen_string_literal: true
module Bundler
  class Plugin::Base
    def self.command(command)
      Plugin.add_command command, self
    end

    def self.add_hook(event, &block)
      Plugin.register_post_install(&block) if event == "post-install"
    end

    def self.source(name)
      Plugin.add_source name, self
    end

    def execute(command, args)
    end
  end
end
