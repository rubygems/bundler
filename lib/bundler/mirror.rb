module Bundler
  class Settings
    class Mirrors
      def initialize(prober = nil)
        @all = Mirror.new
        @prober = prober || TCPSocketProbe.new
        @mirrors = {}
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
          nil
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

      def ==(other)
        !other.nil? && uri == other.uri && fallback_timeout == other.fallback_timeout
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

    class MirrorConfig
      attr_accessor :uri, :value

      def initialize(config_line, value)
        uri, fallback =
          config_line.match(%r{^mirror\.(all|.+?)(\.fallback_timeout)?\/?$}).captures
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

    class TCPSocketProbe
      def replies?(mirror)
        MirrorSockets.new(mirror).any? do |socket, address, timeout|
          begin
            socket.connect_nonblock(address)
          rescue IO::WaitWritable
            wait_for_writtable_socket(socket, address, timeout)
          rescue # Connection failed somehow, again
            false
          end
        end
      end

    private

      def wait_for_writtable_socket(socket, address, timeout)
        if IO.select(nil, [socket], nil, timeout)
          probe_writtable_socket(socket, address)
        else # TCP Handshake timed out, or there is something dropping packets
          false
        end
      end

      def probe_writtable_socket(socket, address)
        socket.connect_nonblock(address)
      rescue Errno::EISCONN
        true
      rescue # Connection failed
        false
      end
    end
  end

  class MirrorSockets
    def initialize(mirror)
      @timeout = mirror.fallback_timeout
      @addresses = Socket.getaddrinfo(mirror.uri.host, mirror.uri.port).map do |address|
        MirrorAddress.new(address[0], address[3], address[1])
      end
    end

    def any?
      @addresses.any? do |address|
        socket = Socket.new(Socket.const_get(address.type), Socket::SOCK_STREAM, 0)
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        value = yield socket, address.to_socket_address, @timeout
        socket.close unless socket.closed?
        value
      end
    end
  end

  class MirrorAddress
    attr_reader :type, :host, :port

    def initialize(type, host, port)
      @type = type
      @host = host
      @port = port
    end

    def to_socket_address
      Socket.pack_sockaddr_in(@port, @host)
    end
  end
end
