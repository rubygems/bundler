module Bundler
  module Plugin
    module V1
      class Lifecycle
        def run(hook_name)
          Bundler.ui.info "The plugin hasn't implemented the run method"
        end
      end

    end
  end
end
