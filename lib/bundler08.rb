require 'pathname'
require 'logger'
require 'set'
require 'erb'
# Required elements of rubygems
require "rubygems/remote_fetcher"
require "rubygems/installer"

require "bundler08/gem_bundle"
require "bundler08/source"
require "bundler08/finder"
require "bundler08/gem_ext"
require "bundler08/resolver"
require "bundler08/environment"
require "bundler08/dsl"
require "bundler08/cli"
require "bundler08/bundle"
require "bundler08/dependency"
require "bundler08/remote_specification"

module Bundler
  VERSION = "0.8.3"

  class << self
    attr_writer :logger, :mode

    def logger
      @logger ||= begin
        logger = Logger.new(STDOUT, Logger::INFO)
        logger.formatter = proc {|_,_,_,msg| "#{msg}\n" }
        logger
      end
    end

    def local?
      @mode == :local
    end

    def writable?
      @mode != :readonly
    end

    def remote?
      @mode == :readwrite
    end
  end

  self.mode = :readonly
end
