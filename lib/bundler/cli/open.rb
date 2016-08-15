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
      spec = Bundler::CLI::Common.select_spec(name, :regex_match)
      begin
        Dir.chdir(spec.full_gem_path) do |path|
          command = Shellwords.split(editor) + [path]
          Bundler.with_clean_env do
            system(*command)
          end || Bundler.ui.info("Could not run '#{command.join(" ")}'")
        end
      rescue Errno::ENOENT
        raise InvalidOption, "Unable to open #{spec.to_s} because the directory it would normally be installed to does not exist. This could happen when you try to open a default gem."
      end
    end
  end
end
