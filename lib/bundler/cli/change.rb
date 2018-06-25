# frozen_string_literal: true

module Bundler
  class CLI::Change
    def initialize(options, gem_name)
      @gem_name = gem_name
      @options = options
    end

    def run
      raise InvalidOption, "Please supply atleast one option to change." if @options.empty?

      definition = Bundler.definition

      @dep = definition.dependencies.find {|d| d.name == @gem_name }

      raise InvalidOption, "`#{@gem_name}` could not be found in the Gemfile." unless @dep

      @pass_options = {}

      initial_gemfile = IO.readlines(Bundler.default_gemfile)

      set_group_options

      set_version_options

      @pass_options[:source] = @options[:source] if @options[:source]

      begin
        require "bundler/cli/remove"
        CLI::Remove.new([@gem_name], {}).run

        require "bundler/cli/add"
        CLI::Add.new(@pass_options, [@gem_name]).run
      rescue StandardError => e
        Bundler.ui.error e
        SharedHelpers.write_to_gemfile(Bundler.default_gemfile, initial_gemfile)
      end
    end

  private

    def set_version_options
      req = @dep.requirement.requirements[0]
      version_prefix = req[0]
      version = req[1].to_s
      case version_prefix
      when "="
        @pass_options[:strict] = true
      when ">="
        @pass_options[:optimistic] = true
      else
        @pass_options[:pessimistic] = true
      end

      @pass_options[:version] = @options[:version].nil? ? version : @options[:version]
    end

    def set_group_options
      groups = @dep.groups
      if @options[:group]
        Bundler.ui.warn "`#{@gem_name}` is already in `#{@options[:group]}`." if groups.include?(@options[:group].to_sym)

        @pass_options["group"] = @options[:group].to_s
      else
        @pass_options["group"] = groups.map(&:to_s).join(",")
      end
    end
  end
end
