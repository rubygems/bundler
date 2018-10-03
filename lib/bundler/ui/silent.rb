# frozen_string_literal: true

module Bundler
  module UI
    class Silent
      attr_writer :shell

      def initialize(options = {})
        @warnings = []
        @logger = options[:logger]
      end

      def add_color(string, color)
        string
      end

      def info(message, newline = nil)
        @logger.log(__method__, msg)
      end

      def confirm(message, newline = nil)
        @logger.log(__method__, msg)
      end

      def warn(message, newline = nil)
        @logger.log(__method__, msg)
        @warnings |= [message]
      end

      def error(message, newline = nil)
        @logger.log(__method__, msg)
      end

      def debug(message, newline = nil)
        @logger.log(__method__, msg)
      end

      def debug?
        false
      end

      def quiet?
        false
      end

      def ask(message)
        @logger.log(__method__, msg)
      end

      def yes?(msg)
        raise "Cannot ask yes? with a silent shell"
      end

      def level=(name)
      end

      def level(name = nil)
      end

      def trace(message, newline = nil, force = false)
        @logger.log(__method__, "#{e.class}: #{e.message}")
      end

      def log_progress
      end

      def silence
        yield
      end

      def unprinted_warnings
        @warnings
      end
    end
  end
end
