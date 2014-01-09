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

    def quiet?
      false
    end

    def debug?
      false
    end

    def ask(message)
    end
  end
end
