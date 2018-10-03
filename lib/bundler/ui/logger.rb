# frozen_string_literal: true

module Bundler
  module UI
    class Logger
      LEVEL_PADDING = UI::Shell::LEVELS.map(&:size).max + 2
      private_constant :LEVEL_PADDING

      attr_reader :io

      def initialize(io)
        @io = io
      end

      def log(level, message)
        return unless io
        level_string = "[#{level}]".rjust(LEVEL_PADDING)
        time = Time.now.utc.strftime("%FT%T.%3NZ")
        prefix = "#{time} #{level_string} "
        padding = prefix.size - 3
        io << prefix << message.gsub(/(?<!\A)^/, " " * padding + " | ") << "\n"
      end

      def path
        io.respond_to?(:path) && io.path
      end

      def flush
        io.respond_to?(:flush) && io.flush
      end
    end
  end
end
