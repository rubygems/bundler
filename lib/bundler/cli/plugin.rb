# frozen_string_literal: true
module Bundler
  class CLI::Plugin
    attr_reader :name, :options

    def initialize(options, name)
      @options = options
      @name = name
    end

    def run
      if @options[:install]
        unless @options[:git]
          puts <<-E
            Only git modules are supported
            Pass the git path with --git option
          E
          return
        end

        Bundler::Plugin.install(@name, @options[:git])
      end
    end
  end
end
