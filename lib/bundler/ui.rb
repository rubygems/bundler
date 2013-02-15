require 'rubygems/user_interaction'

module Bundler
  class UI
    def warn(message, newline = nil)
    end

    def debug(message, newline = nil)
    end

    def trace(message, newline = nil)
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

    def ask(message)
    end

    class Shell < UI
      attr_reader :quiet
      attr_writer :shell

      def initialize(options = {})
        if options["no-color"] || !STDOUT.tty?
          Thor::Base.shell = Thor::Shell::Basic
        end
        @shell = Thor::Base.shell.new
        @quiet = false
        @debug = ENV['DEBUG']
        @trace = ENV['TRACE']
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

      def quiet=(value)
        @quiet = value
      end

      def quiet?
        @quiet
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

      def ask(msg)
        @shell.ask(msg)
      end

      def trace(e, newline = nil)
        msg = ["#{e.class}: #{e.message}", *e.backtrace].join("\n")
        if debug?
          tell_me(msg, nil, newline)
        elsif @trace
          STDERR.puts "#{msg}#{newline}"
        end
      end

    private

      # valimism
      def tell_me(msg, color = nil, newline = nil)
        msg = word_wrap(msg) if newline.is_a?(Hash) && newline[:wrap]
        if newline.nil?
          @shell.say(msg, color)
        else
          @shell.say(msg, color, newline)
        end
      end

      def word_wrap(text, line_width = @shell.terminal_width)
        text.split("\n").collect do |line|
          line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
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
