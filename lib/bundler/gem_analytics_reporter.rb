# frozen_string_literal: true
module Bundler
#include and define class CLI
  class CLI::GemAnalyticsReporter
    attr_reader :options
      def initialize(options)
        @options = options
      end
      
      def enable_reporting
        Bundler.settings[:enable_reporting] ||
          options[:enable_reporting]
      end
      
      def run
        return if enable_reporting == false
        ruby = Bundler::RubyVersion.system
        metrics = {
          engine_gem_version: ruby.engine_gem_version,
          engine_versions: ruby.engine,
          gem_version: ruby.gem_version,
          input_engine: ruby.input_engine,
          patchlevel: ruby.patchlevel,
          versions: ruby.versions,
          bundler_settings: Bundler.settings.all.join(", "),
          bundler_commands: ARGV.join(", "),
        }.freeze
    end
  end
end
