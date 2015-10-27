module Bundler
  module Plugin
    module V1
      class Components
        attr_reader :commands
        attr_reader :sources
        attr_reader :lifecycle_hooks

        def initialize
          @commands = Registry.new
          @sources = Registry.new
          @lifecycle_hooks = Registry.new
        end
      end
    end
  end
end
