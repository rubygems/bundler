# frozen_string_literal: true

module Bundler
  # Dsl to parse the Gemfile looking for plugins to install
  class Plugin::DSL < Bundler::Dsl
    alias_method :_gem, :gem # To use for plugin installation as gem

    # So that we don't have to override all there methods to dummy ones
    # explicitly.
    # They will be handled by method_missing
    [:gemspec, :gem, :path, :install_if, :platforms, :env].each {|m| undef_method m }

    def initialize
      super
      @sources = Plugin::SourceList.new
    end

    def plugin(name, *args)
      _gem(name, *args)
    end

    def method_missing(name, *args)
      super unless Bundler::Dsl.instance_methods.include? name
    end
  end
end
