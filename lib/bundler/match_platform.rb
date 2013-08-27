require 'bundler/gem_helpers'

module Bundler
  module MatchPlatform
    include GemHelpers

    def match_platform(p)
      Gem::Platform::RUBY == platform or
      platform.nil? or p == platform or
      generic(Gem::Platform.new(platform)) == p
    end

    #Match platform used when --platform is used
    def self.match_platform_option(p)
      platform = Dependency.gem_platform(Bundler.settings[:platform].to_sym)
      Gem::Platform::RUBY == p or
      p.nil? or p == platform or
      Gem::Platform.new(p) == platform
    end
  end
end
