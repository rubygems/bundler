class Gem::Platform
  @local = new(ENV['BUNDLER_SPEC_PLATFORM']) if ENV['BUNDLER_SPEC_PLATFORM']
end