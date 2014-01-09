require 'bundler/ui'
require 'rubygems/user_interaction'

module Bundler
  class UI
    class RGProxy < ::Gem::SilentUI
      def initialize(ui)
        @ui = ui
        super()
      end

      def say(message)
        if message =~ /native extensions/
          @ui.info "with native extensions "
        else
          @ui.debug(message)
        end
      end
    end
  end
end