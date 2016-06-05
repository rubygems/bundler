# frozen_string_literal: true
require "rubygems"

class Gem::Platform
  @local = new(ENV["BUNDLER_SPEC_PLATFORM"]) if ENV["BUNDLER_SPEC_PLATFORM"]
end

if ENV["BUNDLER_SPEC_VERSION"]
  module Bundler
    VERSION = ENV["BUNDLER_SPEC_VERSION"].dup
  end
end

if ENV["BUNDLER_SPEC_WINDOWS"] == "true"
  require "bundler/constants"

  module Bundler
    remove_const :WINDOWS if defined?(WINDOWS)
    WINDOWS = true
  end
end

class Object
  if ENV["BUNDLER_SPEC_RUBY_VERSION"]
    remove_const :RUBY_VERSION if defined?(RUBY_VERSION)
    RUBY_VERSION = ENV["BUNDLER_SPEC_RUBY_VERSION"]
  end

  if ENV["BUNDLER_SPEC_RUBY_ENGINE"]
    if defined?(RUBY_ENGINE) && RUBY_ENGINE != "jruby" && ENV["BUNDLER_SPEC_RUBY_ENGINE"] == "jruby"
      begin
        # this has to be done up front because psych will try to load a .jar
        # if it thinks its on jruby
        require "psych"
      rescue LoadError
        nil
      end
    end

    remove_const :RUBY_ENGINE if defined?(RUBY_ENGINE)
    RUBY_ENGINE = ENV["BUNDLER_SPEC_RUBY_ENGINE"]

    if RUBY_ENGINE == "jruby"
      remove_const :JRUBY_VERSION if defined?(JRUBY_VERSION)
      JRUBY_VERSION = ENV["BUNDLER_SPEC_RUBY_ENGINE_VERSION"]
    end
  end
end
