require 'bundler/ui'
require 'rubygems/user_interaction'

module Bundler
  module UI
    class RGProxy < ::Gem::SilentUI
      def initialize(ui)
        @ui = ui
        super()
      end
    end
  end
end
