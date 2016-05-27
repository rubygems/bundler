# frozen_string_literal: true

module Bundler
  # Dsl to parse the Gemfile looking for plugins to install
  class Plugin::Dsl < Bundler::Dsl
    alias_method :_gem, :gem # To use for plugin installation as gem

    # So that we don't have to override all there methods to dummy ones
    # explicitly.
    # They will be handled by missing_methods
    [:gemspec, :gem, :path, :install_if, :platforms, :env].each {|m| undef_method m }

    def initialize
      @sources = Plugin::SourceList.new

      super
    end

    def plugin(name, *args)
      _gem(name, *args)
    end

    def method_missing(name, *args)
      # Dummy evaluation
    end
  end
end
