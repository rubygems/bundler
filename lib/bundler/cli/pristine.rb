# frozen_string_literal: true
require "bundler/cli/common"

module Bundler
  class CLI::Pristine
    def run
      ::Bundler.load.specs.each do |spec|
        gem_name = "#{spec.name} (#{spec.version}#{spec.git_version})"

        if spec.source.instance_of? Source::Path
          ::Bundler.ui.warn("Cannot pristine #{gem_name}. Gem is sourced from local path.")
          next
        end

        if spec.source.instance_of? Source::Rubygems
          cached_gem = spec.cache_file
          unless File.exist?(cached_gem)
            # TODO: Refetch from ruby gem?
            ::Bundler.ui.error("Failed to pristine #{gem_name}. Cached gem #{cached_gem} does not exist.")
            next
          end

          spec.source.install(spec, :force => true)

        elsif spec.source.instance_of? Source::Git
          git_source = spec.source
          git_source.remote!
          git_source.install(spec, :force => true)
        end
      end
    end
  end
end
