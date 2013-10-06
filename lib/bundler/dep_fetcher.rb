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
        uri = @source_uri + "/api/v2/deps/#{name}"
        Bundler.ui.debug "GET #{uri}"
        Bundler.bundle_path.join("deps/#{name}").open("w") do |f|
          f.write @http.request(uri).body
        end
      end
    rescue Net::HTTP::Persistent::Error
      Bundler.ui.debug "Rubygems source #{uri} does not support the dependency index."
      return nil
    end

  end
end
