# frozen_string_literal: true
require "bundler/cli/common"
module Bundler
  class CLI::Inject
    attr_reader :options, :name, :version, :gems, :command
    def initialize(options, name, version, gems, command = "inject")
      @options = options
      @name = name
      @version = version || last_version_number
      @gems = gems
      @command = command
    end

    def run
      # The required arguments allow Thor to give useful feedback when the arguments
      # are incorrect. This adds those first two arguments onto the list as a whole.
      gems.unshift(version).unshift(name)

      # Build an array of Dependency objects out of the arguments
      deps = []
      gems.each_slice(2) do |gem_name, gem_version|
        deps << Bundler::Dependency.new(gem_name, gem_version)
      end

      options = command == "add" ? { remove_timestamp: true } : {}
      added = Injector.inject(deps, options)

      if added.any?
        Bundler.ui.confirm "Added to Gemfile:"
        Bundler.ui.confirm added.map {|g| "  #{g}" }.join("\n")
      else
        Bundler.ui.confirm "All injected gems were already present in the Gemfile"
      end
    end

  private

    def last_version_number
      definition = Bundler.definition(true)
      definition.resolve_remotely!
      specs = definition.index[name].sort_by(&:version)
      unless options[:pre]
        specs.delete_if {|b| b.respond_to?(:version) && b.version.prerelease? }
      end
      spec = specs.last
      spec.version.to_s
    end
  end
end
