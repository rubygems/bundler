module Bundler
  class Source
    class Rubygems
      class Remote
        attr_reader :uri,
                    :anonymized_uri

        def initialize(uri, fallback_auth = nil)
          @uri = apply_auth(uri, fallback_auth).freeze
          @anonymized_uri = remove_auth(@uri).freeze
        end

      private

        def apply_auth(uri, auth = nil)
          if auth && uri.userinfo.nil?
            uri = uri.dup
            uri.userinfo = auth
          end

          uri
        end

        def remove_auth(uri)
          if uri.userinfo
            uri = uri.dup
            uri.user = uri.password = nil
          end

          uri
        end

      end
    end
  end
end
