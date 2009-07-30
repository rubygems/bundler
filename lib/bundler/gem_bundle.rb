module Bundler
  class GemBundle < Array
    def download(repository)
      sort_by {|s| s.full_name.downcase }.each do |spec|
        repository.download(spec)
      end

      self
    end
  end
end