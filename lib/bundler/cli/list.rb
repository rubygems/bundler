# frozen_string_literal: true

module Bundler
  class CLI::List
    def initialize(options)
      @options = options
    end

    def run
      raise InvalidOption, "The `--only` and `--without` options cannot be used together" if @options[:only] && @options[:without]

      raise InvalidOption, "The `--name-only` and `--paths` options cannot be used together" if @options["name-only"] && @options["paths"]

      builder = Dsl.new
      builder.eval_gemfile(Bundler.default_gemfile)

      @definition = builder.to_definition(Bundler.default_lockfile, {})

      verify_group_exists

      @definition.resolve_remotely!

      # get gems that are to be shown from upper and then filter them from specs

      p @definition.specs
      return

      specs = filter_groups.map(&:to_spec).sort_by(&:name)

      return Bundler.ui.info "No gems in the Gemfile" if specs.empty?

      return specs.each {|s| Bundler.ui.info s.name } if @options["name-only"]
      return specs.each {|s| Bundler.ui.info s.full_gem_path } if @options["paths"]

      Bundler.ui.info "Gems included by the bundle:"

      specs.each {|s| Bundler.ui.info "  * #{s.name} (#{s.version}#{s.git_version})" }

      Bundler.ui.info "Use `bundle info` to print more detailed information about a gem"
    end

  private

    def verify_group_exists
      if @options[:without] && !@definition.groups.include?(@options[:without].to_sym)
        raise InvalidOption, "`#{@options[:without]}` group could not be found"
      end

      if @options[:only] && !@definition.groups.include?(@options[:only].to_sym)
        raise InvalidOption, "`#{@options[:only]}` group could not be found"
      end
    end

    def filter_groups
      deps = @definition.dependencies.reject {|d| d.name == "bundler" }

      if @options[:without]
        deps.reject {|d| d.groups.include?(@options[:without].to_sym) }
      elsif @options[:only]
        deps.select {|d| d.groups.include?(@options[:only].to_sym) }
      else
        deps
      end
    end
  end
end
