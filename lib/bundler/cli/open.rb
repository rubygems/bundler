# frozen_string_literal: true
require "bundler/cli/common"
require "shellwords"

module Bundler
  class CLI::Open
    attr_reader :options, :name
    def initialize(options, name)
      @options = options
      @name = name
    end

    def run
      editor = [ENV["BUNDLER_EDITOR"], ENV["VISUAL"], ENV["EDITOR"]].find {|e| !e.nil? && !e.empty? }
      return Bundler.ui.info("To open a bundled gem, set $EDITOR or $BUNDLER_EDITOR") unless editor
      return unless spec = Bundler::CLI::Common.select_spec(name, :regex_match, :include_default => true)
      path = spec.full_gem_path
      Dir.chdir(path) do
        command = Shellwords.split(editor) + [path]
        Bundler.with_clean_env do
          system(*command)
        end || Bundler.ui.info("Could not run '#{command.join(" ")}'")
      end
    end
  end
end
