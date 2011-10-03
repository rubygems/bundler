require 'rubygems/user_interaction'

module Bundler
  class UI
    def warn(message, newline = nil)
    end

    def debug(message, newline = nil)
    end

    def error(message, newline = nil)
    end

    def info(message, newline = nil)
    end

    def confirm(message, newline = nil)
    end

    def debug?
      false
    end

    class Shell < UI
      attr_writer :shell

      def initialize(shell)
        @shell = shell
        @quiet = false
        @debug = ENV['DEBUG']
      end

      def info(msg, newline = nil)
        tell_me(msg, nil, newline) if !@quiet
      end

      def confirm(msg, newline = nil)
        tell_me(msg, :green, newline) if !@quiet
      end

      def warn(msg, newline = nil)
        tell_me(msg, :yellow, newline)
      end

      def error(msg, newline = nil)
        tell_me(msg, :red, newline)
      end

      def be_quiet!
        @quiet = true
      end

      def debug?
        # needs to be false instead of nil to be newline param to other methods
        !!@debug && !@quiet
      end

      def debug!
        @debug = true
      end

      def debug(msg, newline = nil)
        tell_me(msg, nil, newline) if debug?
      end

      private
      # valimism
      def tell_me(msg, color = nil, newline = nil)
        newline.nil? ? @shell.say(msg, color) : @shell.say(msg, color, newline)
      end
    end

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
