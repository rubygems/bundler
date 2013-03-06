module Bundler
  class RubygemsMirror

    def self.to_uri(uri)
      # NOTE: implementation of Settings forces case insensitivity, which
      # breaks case sensitive URIs (like file paths). We therefore need to do
      # lookups on downcased URIs.
      lookup_uri = URI(uri.to_s.downcase)
      mirrors[lookup_uri] || uri
    end

    private

    def self.mirrors
      Bundler.settings.gem_mirrors
    end

  end
end
