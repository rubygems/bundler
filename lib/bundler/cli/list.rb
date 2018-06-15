# frozen_string_literal: true

module Bundler
  class CLI::List
    def initialize(options)
      @options = options
    end

    def run
      raise InvalidOption, "The `--only` and `--without` options cannot be used together" if @options[:only] && @options[:without]

      raise InvalidOption, "The `--name-only` and `--paths` options cannot be used together" if @options["name-only"] && @options[:paths]

      specs = if @options[:only] || @options[:without]
        filtered_specs_by_groups
      else
        Bundler.load.specs
      end.reject {|s| s.name == "bundler" }.sort_by(&:name)

      return Bundler.ui.info "No gems in the Gemfile" if specs.empty?

      return specs.each {|s| Bundler.ui.info s.name } if @options["name-only"]
      return specs.each {|s| Bundler.ui.info s.full_gem_path } if @options["paths"]

      Bundler.ui.info "Gems included by the bundle:"

      specs.each {|s| Bundler.ui.info "  * #{s.name} (#{s.version}#{s.git_version})" }

      Bundler.ui.info "Use `bundle info` to print more detailed information about a gem"
    end

  private

    def verify_group_exists(groups)
      raise InvalidOption, "`#{@options[:without]}` group could not be found." if @options[:without] && !groups.include?(@options[:without].to_sym)

      raise InvalidOption, "`#{@options[:only]}` group could not be found." if @options[:only] && !groups.include?(@options[:only].to_sym)
    end

    def filtered_specs_by_groups
      definition = Bundler.definition
      groups = definition.groups

      verify_group_exists(groups)

      show_groups =
        if @options[:without]
          groups.reject {|g| g == @options[:without].to_sym }
        elsif @options[:only]
          groups.select {|g| g == @options[:only].to_sym }
        else
          groups
        end.map(&:to_sym)

      definition.specs_for(show_groups)
    end
  end
end
