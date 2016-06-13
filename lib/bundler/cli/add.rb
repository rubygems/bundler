# frozen_string_literal: true
require "bundler/cli/common"
module Bundler
  class CLI::Add
    attr_reader :options, :name, :version, :gems
    def initialize(options, name, version, gems)
      @options = options
      @name = name
      @version = version || last_version_number
      @gems = gems
    end

    def run
      gems.unshift(version).unshift(name)

      deps = []
      gems.each_slice(2) do |gem_name, gem_version|
        deps << Bundler::Dependency.new(gem_name, gem_version)
      end

      added = Injector.inject(deps)

      if added.any?
        Bundler.ui.confirm "Added to Gemfile:"
        Bundler.ui.confirm added.map {|g| "  #{g}" }.join("\n")
      else
        Bundler.ui.confirm "All specified gems are already present in the Gemfile"
      end
    end

  private

    def last_version_number
      definition = Bundler.definition(true)
      definition.resolve_remotely!
      specs = definition.index[name].sort_by(&:version)
      spec = specs.delete_if {|b| b.respond_to?(:version) && b.version.prerelease? }
      spec = specs.last
      spec.version.to_s
    end
  end
end
