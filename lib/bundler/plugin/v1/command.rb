module Bundler
  module Plugin
    module V1
      class Command
        attr_reader :command_name, :command_short_description, :command_long_description

        def initialize
          @command_name = "Plugin [OPTIONS]"
          @command_short_description = "Unimplemented short description"
          @command_long_description = "Unimplemented long description"
        end

        def run(options, args)
          Bundler.ui.info "The plugin hasn't implemented the run method"
        end
      end
    end
  end
end
