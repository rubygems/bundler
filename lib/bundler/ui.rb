module Bundler
  class UI
    def warn(message)
    end

    def error(message)
    end

    def info(message)
    end

    def confirm(message)
    end

    class Shell < UI
      def initialize(shell)
        @shell = shell
      end

      def info(msg)
        @shell.say(msg)
      end

      def confirm(msg)
        @shell.say(msg, :green)
      end

      def warn(msg)
        @shell.say(msg, :yellow)
      end

      def error(msg)
        @shell.say(msg, :error)
      end
    end

    class RGProxy < Gem::SilentUI
      def initialize(ui)
        @ui = ui
      end

      def say(message)
        if message =~ /native extensions/
          @ui.info "  * #{message}"
        else
          @ui.info(message)
        end
      end
    end
  end
end