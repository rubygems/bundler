module Bundler
  class Settings
    class Mirrors
      def initialize(prober = nil)
        @all = Mirror.new
        @prober = prober || TCPSocketProbe.new
        @mirrors = Hash.new
      end

      def for(uri)
        if @all.validate!(@prober).valid?
          @all
        else
          fetch_valid_mirror_for(AbsoluteURI.normalize(uri))
        end
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
          mirror = (@mirrors[config.uri] = @mirrors[config.uri] || Mirror.new)
        end
        config.update_mirror(mirror)
      end

      private

      def fetch_valid_mirror_for(uri)
        mirror = (@mirrors[uri] || Mirror.new(uri)).validate!(@prober)
        mirror = Mirror.new(uri) unless mirror.valid?
        mirror
      end
    end

    class Mirror
      DEFAULT_FALLBACK_TIMEOUT = 0.1

      attr_reader :uri, :fallback_timeout

      def initialize(uri = nil, fallback_timeout = 0)
        self.uri = uri
        self.fallback_timeout = fallback_timeout
        @valid = nil
      end

      def uri=(uri)
        @uri = if uri.nil?
                 uri = nil
               else
                 URI(uri.to_s)
               end
        @valid = nil
      end

      def fallback_timeout=(timeout)
        case timeout
        when true, "true"
          @fallback_timeout = DEFAULT_FALLBACK_TIMEOUT
        when false, "false"
          @fallback_timeout = 0
        else
          @fallback_timeout = timeout.to_i
        end
        @valid = nil
      end

      def ==(o)
        o != nil && self.uri == o.uri && self.fallback_timeout == o.fallback_timeout
      end

      def valid?
        return false if @uri.nil?
        return @valid unless @valid.nil?
        false
      end

      def validate!(probe = nil)
        @valid = false if uri.nil?
        if @valid.nil?
          @valid = fallback_timeout == 0 || (probe || TCPSocketProbe.new).replies?(self)
        end
        self
      end
    end

    class TCPSocketProbe
      def replies?(mirror)
        true
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
