module Bundler
  class Settings
    class Mirrors
      def initialize
        @all = Mirror.new
        @mirrors = Hash.new { |h, k| h[k] = Mirror.new }
      end

      def [](key)
        @mirrors[URI(key.to_s)]
      end

      def fetch(key, &block)
        @mirrors.fetch(key, &block)
      end

      def each
        @mirrors.each do |k, v|
          yield k, v.uri.to_s
        end
      end

      def parse(key, value)
        config = MirrorConfig.new(key, value)
        if config.all?
          mirror = @all
        else
          mirror = self[config.uri]
        end
        config.update_mirror(mirror)
      end
    end

    class Mirror
      DEFAULT_FALLBACK_TIMEOUT = 0.1

      attr_reader :uri, :fallback_timeout

      def initialize(uri = nil, fallback_timeout = 0)
        self.uri = uri
        self.fallback_timeout = fallback_timeout
      end

      def uri=(uri)
        @uri = URI(uri.to_s)
      end

      def fallback_timeout=(timeout)
        case timeout
        when true
          @fallback_timeout = DEFAULT_FALLBACK_TIMEOUT
        when false
          @fallback_timeout = 0
        else
          @fallback_timeout = timeout.to_i
        end
      end

      def ==(o)
        self.class == o.class && self.uri == o.uri && self.fallback_timeout == o.fallback_timeout
      end

      def valid?
        ! @uri.nil?
      end
    end

    private

    class MirrorConfig
      attr_reader :uri, :value
      def initialize(config_line, value)
        all, uri, fallback =
          config_line.match(/^mirror(\.all)?\.(.+?)(\.fallback_timeout)?\/?$/).captures
        @all = !all.nil?
        @fallback = !fallback.nil?
        @uri = AbsoluteURI.normalize(uri)
        @value = value
      end

      def all?
        @all
      end

      def update_mirror(mirror)
        if @fallback
          mirror.fallback_timeout = @value
        else
          mirror.uri = AbsoluteURI.normalize(@value)
        end
      end
    end
  end
end
