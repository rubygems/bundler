module Bundler
  class Settings
    class Mirrors
      def initialize(prober = nil)
        @prober = prober || TCPProbe.new
        @all = Mirror.new
        @mirrors = Hash.new { |h, k| h[k] = Mirror.new }
      end

      def [](key)
        @mirrors[URI(key.to_s)]
      end

      def for(uri)
        return @all.uri if @all.valid?
        uri = AbsoluteURI.normalize(uri)
        return uri unless @mirrors[uri]
        mirror = @mirrors[uri]
        @prober.probe(mirror)
        mirror.uri
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
        @uri = if uri.nil?
                 uri = nil
               else
                 URI(uri.to_s)
               end
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

    class TCPProbe
      def probe(uri)
      end
    end

    private

    class MirrorConfig
      attr_accessor :uri, :value

      def initialize(config_line, value)
        uri, fallback =
          config_line.match(/^mirror\.(all|.+?)(\.fallback_timeout)?\/?$/).captures
        @fallback = !fallback.nil?
        @all = false
        if uri == "all"
          @all = true
        else
          @uri = AbsoluteURI.normalize(uri)
        end
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
