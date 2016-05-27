# frozen_string_literal: true

module Bundler
  # SourceList object to be used while parsing the Gemfile, setting the
  # approptiate options to be used with Source classes for plugin installation
  class Plugin::SourceList < Bundler::SourceList
    def initialize
      @rubygems_aggregate = Source::Rubygems.new :plugin => true
      super
    end

    def add_git_source(options = {})
      add_source_to_list Source::Git.new(options.merge(:plugin => true)), git_sources
    end

    def add_rubygems_source(options = {})
      add_source_to_list Source::Rubygems.new(options.merge(:plugin => true)), @rubygems_sources
    end
  end
end
