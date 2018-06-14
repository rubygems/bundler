# frozen_string_literal: true

module Bundler
  class CLI::Change
    def initialize(options, gem_name)
      @gem_name = gem_name
      @options = options
    end

    def run
      builder = Dsl.new
      builder.eval_gemfile(Bundler.default_gemfile)

      @definition = builder.to_definition(Bundler.default_lockfile, {})

      raise InvalidOption, "`#{@gem_name}` could not be found in the Gemfile." unless @definition.dependencies.find {|d| d.name == @gem_name }
    end
  end
end
