# frozen_string_literal: true

module Bundler
  class CLI::Change
    def initialize(options, gem_name)
      @gem_name = gem_name
      @options = options
    end

    def run
      raise InvalidOption, "Please supply at least one option to change." unless @options[:group] || @options[:version] || @options[:source]

      dep = Bundler.definition.dependencies.find {|d| d.name == @gem_name }

      raise InvalidOption, "`#{@gem_name}` could not be found in the Gemfile." unless dep

      add_options = {}

      initial_gemfile = IO.readlines(Bundler.default_gemfile)

      set_group_options(dep.groups, add_options)

      set_version_options(dep.requirement, add_options)

      add_options["source"] = @options[:source] if @options[:source]

      begin
        require "bundler/cli/remove"
        CLI::Remove.new([@gem_name], {}).run

        require "bundler/cli/add"
        CLI::Add.new(add_options, [@gem_name]).run
      rescue StandardError => e
        SharedHelpers.write_file(Bundler.default_gemfile, initial_gemfile)
        raise e
      end
    end

  private

    # If version of the gem is specified in Gemfile then we preserve
    # it and the prefix
    # else if @options[:version] is present then we prefer strict version
    # and for a empty version we let resolver get version and set as pessimistic
    #
    # @param [requirement] requirement   requirement of the gem.
    # @param [Hash]        add_options   Options to pass to add command
    # @return
    def set_version_options(requirement, add_options)
      req = requirement.requirements[0]
      version_prefix = req[0]
      version = req[1].to_s
      case version_prefix
      when "="
        add_options[:strict] = true
      when ">="
        add_options[:optimistic] = true unless version == "0"
      else
        add_options[:pessimistic] = true
      end

      add_options[:version] = if @options[:version].nil?
        version.to_i.zero? ? nil : version
      else
        @options[:version]
      end
    end

    # @param [groups] groups      Groups of the gem.
    # @param [Hash]   add_options Options to pass to add command
    # @return
    def set_group_options(groups, add_options)
      if @options[:group]
        uniq_groups = @options[:group].split(",").uniq
        common_groups = uniq_groups & groups.map(&:to_s)

        Bundler.ui.warn "`#{@gem_name}` is already present in `#{common_groups.join(",")}`." unless common_groups.empty?

        add_options["group"] = uniq_groups.join(",")
      else
        add_options["group"] = groups.map(&:to_s).join(",")
      end
    end
  end
end
