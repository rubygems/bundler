# frozen_string_literal: true
module Bundler
  class Hooks
    @hooks = {}

    class << self
      # Run the hooks for the given hook name
      def run(name)
        Bundler.ui.info("Running '#{name}' hooks.") unless hooks_for(name).empty?

        hooks_for(name).each(&:call)
      end

      # Register a block for the given hook_name
      def register_hook(hook_name, block)
        hooks_for(hook_name).each do |blk|
          # Simple but effective proc compartion
          return nil if blk.source_location == block.source_location
        end
        hooks_for(hook_name) << block
      end

    private

      def hooks_for(hook_name)
        @hooks[hook_name] ||= []
      end
    end
  end
end
