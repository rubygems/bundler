# frozen_string_literal: true

module Bundler
  # Dsl to parse the Gemfile looking for plugins to install
  module Plugin
    class DSL < Bundler::Dsl
      class PluginGemfileError < PluginError; end
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
        raise PluginGemfileError, "Undefined local variable or method `#{name}' for Gemfile" unless Bundler::Dsl.method_defined? name
      end

      def source(source, *args, &blk)
        options = args.last.is_a?(Hash) ? args.pop.dup : {}
        options = normalize_hash(options)
        return super unless options && options.key?("type")

        plugin("bundler-source-#{options["type"].to_s}")
      end
    end
  end
end
