module Bundler
  class DepFetcher

    def initialize(source_uri)
      @source_uri = source_uri
    end

    def fetch(names)
      Bundler.bundle_path.join("deps").mkpath

      names.each do |name|
        deps = File.read File.expand_path("~/src/bundler/new-index/deps/#{name}")
        Bundler.bundle_path.join("deps/#{name}").open("w"){|f| f.write(deps) }
      end
    end

  end
end
