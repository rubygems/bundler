# frozen_string_literal: true

module Bundler
  class CLI::Remove
    def initialize(gems, options)
      @gems = gems
      @options = options
    end

    def run
      # Raise error if no gems are specified
      raise InvalidOption, "Please specify gems to remove" if @gems.empty?

      removed_deps = Injector.remove(@gems, {})

      # Remove gems from .bundle if install flag is specified
      Installer.install(Bundler.root, Bundler.definition) if @options["install"]

      removed_deps.each {|dep| Bundler.ui.confirm "#{SharedHelpers.pretty_dependency(dep)} was removed." }
    end
  end
end
