# frozen_string_literal: true
module Bundler
  class CLI::Cache
    attr_reader :options
    def initialize(options)
      @options = options
    end

    def run
      Bundler.definition.validate_ruby!
      Bundler.definition.resolve_with_cache!
      Bundler.settings[:cache_all] = true
      Bundler.settings[:cache_all_platforms] = options["all-platforms"] if options.key?("all-platforms")
      Bundler.load.cache
      Bundler.settings[:no_prune] = true if options["no-prune"]
      Bundler.load.lock
    rescue GemNotFound => e
      Bundler.ui.error(e.message)
      Bundler.ui.warn "Run `bundle install` to install missing gems."
      exit 1
    end
  end
end
