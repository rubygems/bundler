module Bundler
  module UI
    class Silent
      def info(_message, _newline = nil)
      end

      def confirm(_message, _newline = nil)
      end

      def warn(_message, _newline = nil)
      end

      def error(_message, _newline = nil)
      end

      def debug(_message, _newline = nil)
      end

      def debug?
        false
      end

      def quiet?
        false
      end

      def ask(_message)
      end

      def level=(_name)
      end

      def level(_name = nil)
      end

      def trace(_message, _newline = nil)
      end

      def silence
        yield
      end
    end
  end
end
