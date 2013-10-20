module Bundler
  module Source
    autoload :Rubygems, 'bundler/source/rubygems'
    autoload :Path,     'bundler/source/path'
    autoload :Git,      'bundler/source/git'

    def self.mirror_for(uri)
      uri = URI(uri.to_s) unless uri.is_a?(URI)

      # Settings keys are all downcased
      mirrors = Bundler.settings.gem_mirrors
      normalized_key = URI(uri.to_s.downcase)

      mirrors[normalized_key] || uri
    end

  end
end
