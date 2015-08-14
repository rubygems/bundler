require "bundler/plugin/v1/components"
require "bundler/plugin/v1/lifecycle"
module Bundler
  module Plugin
    module V1
      # This is the superclass for all V1 plugins.
      class Plugin
        ROOT_CLASS = self
        def self.command(name, &block)

          # Validate the name of the command
          if name.to_s !~ /^[-a-z0-9]+$/i
            raise InvalidCommandName, "Commands can only contain letters, numbers, and hyphens"
          end

          if Bundler.plugin_install_mode
            Bundler.ui.info "Setting up '#{name}' subcommand"
          end

          components.commands.register(name.to_sym) do
            block
          end

          nil
        end

        def self.source(name, &block)

          if Bundler.plugin_install_mode
            Bundler.ui.info "Setting up '#{name}' custom source"
          end

          components.sources.register(name.to_sym) do
            block
          end

          nil
        end

        def self.lifecycle(names, &block)
          raise ArgumentError, "must provide an array of hooks to register" unless names.is_a?(Enumerable)

          names.each do |hook|
            if Bundler.plugin_install_mode
              Bundler.ui.info "Setting up '#{hook}' lifecycle hook"
            end

            lifecycle_class = block.call
            lifecycle_object = lifecycle_class.new

            components.lifecycle_hooks.register_hook(hook.to_sym, lifecycle_object)
          end

          nil
        end

        def self.name(name)
          # Get or set the value first, so we have a name for logging when
          # we register.
          result = get_or_set(:name, name)

          # The plugin should be registered if we're setting a real name on it
          Plugin.manager.register(self)

          # Return the result
          result
        end

        def self.get_or_set(key, value)
          # Otherwise set the value
          data[key] = value
        end

        def self.data
          @data ||= {}
        end

        def self.manager
          @manager ||= Manager.new
        end

        def self.components
          @components ||= Components.new
        end
      end

    end
  end
end
