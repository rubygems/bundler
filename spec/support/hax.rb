# frozen_string_literal: true
require "rubygems"

class Gem::Platform
  @local = new(ENV["BUNDLER_SPEC_PLATFORM"]) if ENV["BUNDLER_SPEC_PLATFORM"]
end
Gem.platforms.clear

stub_const = proc do |mod, const, val|
  $bundler_spec_stubbed_constants ||= {} # rubocop:disable Style/GlobalVars
  orig_val = mod.send(:remove_const, const) if mod.const_defined?(const)
  $bundler_spec_stubbed_constants[[mod, const]] = orig_val # rubocop:disable Style/GlobalVars
  mod.send(:const_set, const, val)
end

if ENV["BUNDLER_SPEC_VERSION"]
  module Bundler; end
  stub_const.call(Bundler, :VERSION, ENV["BUNDLER_SPEC_VERSION"].dup)
end

if ENV["BUNDLER_SPEC_WINDOWS"] == "true"
  require "bundler/constants"
  stub_const.call(Bundler, :WINDOWS, true)
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

  stub_const.call(Object, :RUBY_ENGINE, ENV["BUNDLER_SPEC_RUBY_ENGINE"])

  if RUBY_ENGINE == "jruby"
    stub_const.call(Object, :JRUBY_VERSION, ENV["BUNDLER_SPEC_RUBY_ENGINE_VERSION"])
  end
end

if artifice = ENV["BUNDLER_SPEC_ARTIFICE_ENDPOINT"]
  require File.expand_path("../artifice/#{artifice}", __FILE__)
  name = artifice.to_s.gsub(/((?:^|_).)/) {|s| s.delete("_").upcase }.gsub("Api", "API")
  Artifice.activate_with(Artifice.const_get(name, false))
  require "rubygems/request"
  Gem::Request::ConnectionPools.client = ::Net::HTTP if defined?(Gem::Request::ConnectionPools)
  class Gem::RemoteFetcher
    @fetcher = nil
  end
end
