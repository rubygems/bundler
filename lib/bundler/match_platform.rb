require "bundler/gem_helpers"

module Bundler
  module MatchPlatform
    include GemHelpers

    def match_platform(p)
      Gem::Platform::RUBY == platform ||
        platform.nil? || p == platform ||
        generic(Gem::Platform.new(platform)) === p
    end
  end
end
