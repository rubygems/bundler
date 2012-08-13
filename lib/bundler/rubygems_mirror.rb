module Bundler
  class RubygemsMirror

    private

    def self.mirrors
      @mirrors ||= Bundler.settings.all.inject({}) do |h, k|
        if k =~ /^mirror./
          uri = add_slash(k.sub(/^mirror./, ''))
          h[uri] = URI.parse(Bundler.settings[k])
        end
        h
      end
    end

    def self.add_slash(uri)
      uri = uri.to_s
      uri =~ /\/$/ ? uri : uri + '/'
    end

    public

    def self.to_uri(uri)
      mirrors[add_slash(uri)] || uri
    end
  end
end
