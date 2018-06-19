# frozen_string_literal: true

module Bundler
  class CLI::Change
    def initialize(options, gem_name)
      @gem_name = gem_name
      @options = options
    end

    def run
      @definition = Bundler.definition

      raise InvalidOption, "`#{@gem_name}` could not be found in the Gemfile." unless @definition.dependencies.find {|d| d.name == @gem_name }

      pass_options = {
        "group" => [],
        "version" => nil,
        "source" => nil
      }
      pass_options["group"] << @options[:group] if @options[:group]

      require "bundler/cli/remove"
      CLI::Remove.new([@gem_name], {}).run

      require "bundler/cli/add"
      CLI::Add.new(pass_options, [@gem_name]).run
    end
  end
end
