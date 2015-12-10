module Bundler
  class Settings
    class Mirrors
      def initialize(prober = nil)
        @all = Mirror.new
        @prober = prober || MirrorProber.new
        @mirrors = Hash.new
      end

      def for(uri)
        uri = AbsoluteURI.normalize(uri)
        validate_mirror_for_all
        validate_mirror_for(uri)
        if @all.valid?
          @all
        else
          mirror = fetch_valid_mirror_for(uri) || Mirror.new(uri)
          mirror
        end
      end

      def fetch_valid_mirror_for(uri)
        mirror = @mirrors[uri]
        return nil if mirror.nil?
        return nil unless mirror.valid?
        mirror
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
          mirror = @mirrors[config.uri] || Mirror.new
          @mirrors[config.uri] = mirror
        end
        config.update_mirror(mirror)
      end

      private

      def validate_mirror_for_all
        MirrorProbing.new(@all, @prober).probe! if @all.valid?
      end

      def validate_mirror_for(uri)
        mirror = @mirrors[uri]
        MirrorProbing.new(mirror, @prober).probe! unless mirror.nil?
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
        o != nil && self.uri == o.uri && self.fallback_timeout == o.fallback_timeout
      end

      def valid?
        return @valid unless @valid.nil?
        ! @uri.nil?
      end

      def validate!
        @valid = true
      end

      def invalidate!
        @valid = false
      end

      def validated_already?
        ! @valid.nil?
      end
    end

    class MirrorProber
      def probe_availability(mirror)
        true
      end
    end

    private

    class MirrorProbing
      def initialize(mirror, prober)
        @mirror = mirror
        @prober = prober
      end

      def probe!
        return @mirror if @mirror.validated_already?
        if @prober.probe_availability(@mirror)
          @mirror.validate!
        else
          @mirror.invalidate!
        end
        @mirror
      end
    end

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
