# frozen_string_literal: true
require "rubygems"

module BundlerSpecOriginal
  UNSET = Module.new
  GEM_PLATFORM_LOCAL = Gem::Platform.local
  CONSTANTS = Hash[
    %w[Bundler::VERSION Bundler::WINDOWS Object::RUBY_ENGINE Object::RUBY_ENGINE_VERSION].map do |const|
      value = const.split("::").reduce(Module) {|ns, c| ns.const_defined?(c) ? ns.const_get(c) : UNSET }
      [const, value]
    end
  ]

  def self.reset!
    Gem.module_exec { @platforms = nil }
    Gem::Platform.module_exec { @local = BundlerSpecOriginal::GEM_PLATFORM_LOCAL }

    CONSTANTS.each do |name, value|
      parts = name.split("::")
      sym = parts.pop
      namespace = parts.reduce(Module) {|ns, c| ns.const_get(c) }
      namespace.send(:remove_const, sym) if namespace.const_defined?(sym)
      namespace.const_set(sym, value) unless UNSET == value
    end
    Object.send :remove_const, :BundlerSpecOriginal
  end
end

module Gem
  class Platform
    @local = new(ENV["BUNDLER_SPEC_PLATFORM"]) if ENV["BUNDLER_SPEC_PLATFORM"]
  end
  @platforms = [Gem::Platform::RUBY, Gem::Platform.local]
end

if ENV["BUNDLER_SPEC_VERSION"]
  module Bundler
    remove_const(:VERSION) if const_defined?(:VERSION)
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
