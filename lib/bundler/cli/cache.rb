# frozen_string_literal: true
module Bundler
  class CLI::Cache
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      Bundler.ui.level = "error" if options[:quiet]
      # TODO: Also need to remove options[:path] here
      Bundler.settings[:path] = File.expand_path(options[:path]) if options[:path]
      Bundler.settings[:cache_all_platforms] = options["all-platforms"] if options.key?("all-platforms")
      Bundler.settings[:cache_path] = options["cache-path"] if options.key?("cache-path")

      install

      custom_path = Pathname.new(options[:path]) if options[:path]
      Bundler.load.cache(custom_path)
    end

  private

    def install
      require "bundler/cli/install"
      options = self.options.dup
      if Bundler.settings[:cache_all_platforms]
        options["local"] = false
        options["update"] = true
      end
      Bundler::CLI::Install.new(options).run
    end
  end
end
