# frozen_string_literal: true

module Bundler
  class Plugin::Dsl < Bundler::Dsl
    alias_method :_gem, :gem # To use for plugin installation as gem

    # So that we don't have to overwrite all there methods to dummy ones
    [:gemspec, :gem, :path, :install_if, :platforms, :env]
    .each {|m| undef_method m}

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
