require 'bundler/vendored_persistent'

module Bundler
  class DepFetcher

    def initialize(source_uri)
      @source_uri = source_uri
      @http = Net::HTTP::Persistent.new("bundler")
    end

    def fetch(names)
      Bundler.bundle_path.join("deps").mkpath

      names.each do |name|
        deps = @http.request(@source_uri + "/api/v2/deps/#{name}").body
        Bundler.bundle_path.join("deps/#{name}").open("w"){|f| f.write(deps) }
      end
    end

  end
end
