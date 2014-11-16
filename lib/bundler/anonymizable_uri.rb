module Bundler
  class AnonymizableURI
    attr_reader :original_uri,
                :without_credentials

    def initialize(original_uri)
      @original_uri = original_uri.freeze
      @without_credentials ||=
        if original_uri.userinfo
          original_uri.dup.tap { |uri| uri.user = uri.password = nil }.freeze
        else
          original_uri
        end
    end
  end
end
