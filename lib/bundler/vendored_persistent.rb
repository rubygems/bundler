# frozen_string_literal: true

# We forcibly require OpenSSL, because net/http/persistent will only autoload
# it. On some Rubies, autoload fails but explicit require succeeds.
begin
  require "openssl"
rescue LoadError
  # some Ruby builds don't have OpenSSL
end
module Bundler
  module Persistent
    module Net
      module HTTP
      end
    end
  end
end
require "bundler/vendor/net-http-persistent/lib/net/http/persistent"

module Bundler
  class PersistentHTTP < Persistent::Net::HTTP::Persistent
    def connection_for(uri)
      connection = super
      warn_old_tls_version_rubygems_connection(uri, connection)
      connection
    end

    def warn_old_tls_version_rubygems_connection(uri, connection)
      return unless connection.use_ssl?
      return unless (uri.host || "").end_with?("rubygems.org")

      socket = connection.instance_variable_get(:@socket)
      socket_io = socket.io
      return unless socket_io.respond_to?(:ssl_version)
      ssl_version = socket_io.ssl_version

      case ssl_version
      when /TLSv([\d\.]+)/
        version = Gem::Version.new($1)
        if version < Gem::Version.new("1.1")
          Bundler.ui.warn "Your Ruby version does not support TLSv1.1 or newer" \
            ", which will be required to connect to https://#{uri.hostname}" \
            " by January 2018."
        end
      end
    end
  end
end
