class Gem::Platform
  @local = new(ENV['BUNDLER_SPEC_PLATFORM']) if ENV['BUNDLER_SPEC_PLATFORM']
end

if ENV['BUNDLER_SPEC_VERSION']
  module Bundler
    VERSION = ENV['BUNDLER_SPEC_VERSION'].dup
  end
end