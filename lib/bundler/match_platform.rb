require 'bundler/gem_helpers'

module Bundler
  module MatchPlatform
    include GemHelpers

    def match_platform(p)
      pmatch = (Gem::Platform::RUBY == platform or
      platform.nil? or p == platform or
      generic(Gem::Platform.new(platform)) == p)
      if required_ruby_version
        system = Gem::Version.new(Bundler::SystemRubyVersion.new.version)
        pmatch && required_ruby_version.satisfied_by?(system)
      else
        pmatch
      end
    end
  end
end
