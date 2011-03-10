require 'rubygems/user_interaction'

module Bundler
  class UI
    def warn(message)
    end

    def debug(message)
    end

    def error(message)
    end

    def info(message)
    end

    def confirm(message)
    end

    class Shell < UI
      attr_writer :shell

      def initialize(shell)
        @shell = shell
        @quiet = false
        @debug = ENV['DEBUG']
      end

      def debug(msg)
        @shell.say(msg) if @debug && !@quiet
      end

      def info(msg)
        @shell.say(msg) if !@quiet
      end

      def confirm(msg)
        @shell.say(msg, :green) if !@quiet
      end

      def warn(msg)
        @shell.say(msg, :yellow)
      end

      def error(msg)
        @shell.say(msg, :red)
      end

      def be_quiet!
        @quiet = true
      end

      def debug!
        @debug = true
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
