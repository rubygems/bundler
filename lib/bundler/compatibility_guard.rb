# frozen_string_literal: true
require "rubygems"

if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.0.0")
  abort "Bundler 2 requires Ruby 2+. Either install bundler 1 or update to a supported Ruby version."
end
if Gem::Version.new(Gem::VERSION) < Gem::Version.new("2.0.0")
  abort "Bundler 2 requires RubyGems 2+. Either install bundler 1 or update to a supported RubyGems version."
end
