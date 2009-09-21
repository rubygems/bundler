module Bundler
  class GemBundle < Array
    def download
      sort_by {|s| s.full_name.downcase }.each do |spec|
        spec.source.download(spec)
      end

      self
    end
  end
end