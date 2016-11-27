# frozen_string_literal: true
module Bundler
  class CLI::ReportMetrics
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
          bundler = Bundler
            ruby = Bundler::RubyVersion.system
             metrics = {
                        engine_gem_version: ruby.engine_gem_version,
                        engine_versions: ruby.engine,
                        gem_version: ruby.gem_version,
                        input_engine: ruby.input_engine,
                        patchlevel: ruby.patchlevel,
                        versions: ruby.versions,
                        bundler_settings: bundler.settings.all.join(", ")
                        bundler_commands: ARGV.join(", ")
             }.freeze
                       
          #uri = URI('rubygems.org/app/controllers/api/v2/metrics_controller.rb')
          #Net::HTTP.post_form(uri,metrics)
          #generate a response in the server once info has been sent aka. render nothing true
      end
  end
end
