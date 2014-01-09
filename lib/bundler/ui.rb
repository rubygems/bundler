module Bundler
  class UI
    autoload :RGProxy, 'bundler/ui/rg_proxy'
    autoload :Shell,   'bundler/ui/shell'

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

    def silence
      yield
    end
  end
end
