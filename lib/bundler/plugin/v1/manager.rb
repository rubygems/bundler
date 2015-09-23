module Bundler
  module Plugin
    module V1
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager
        attr_reader :registered

        def initialize
          @registered = []
        end

        def commands
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.commands)
            end
          end
        end

        def lifecycle_hooks
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.lifecycle_hooks)
            end
          end
        end

        def call_hook(hook, *args)
          if lifecycle_hooks.all[hook].is_a?(Array)
            lifecycle_hooks.all[hook].each do |hook_object|
              hook_object.run(hook, args)
            end
          end
        end

        def sources
          Registry.new.tap do |result|
            @registered.each do |plugin|
              result.merge!(plugin.components.sources)
            end
          end
        end

        def register(plugin)
          unless @registered.include?(plugin)
            if Bundler.plugin_install_mode
              Bundler.ui.info "Registered plugin '#{plugin.name}'"
            end
            @registered << plugin
          end
        end
      end
    end
  end
end
