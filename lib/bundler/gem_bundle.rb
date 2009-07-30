module Bundler
  class GemBundle < Array
    def download(directory)
      FileUtils.mkdir_p(directory)

      sort_by {|s| s.full_name.downcase }.each do |spec|
        unless directory.join("cache", "#{spec.full_name}.gem").file?
          Bundler.logger.info "Downloading #{spec.full_name}.gem"
          Gem::RemoteFetcher.fetcher.download(spec, spec.source, directory)
        end
      end

      self
    end
  end
end