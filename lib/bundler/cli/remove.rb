# frozen_string_literal: true

module Bundler
  class CLI::Remove
    def initialize(gem_name)
      @gem_name = gem_name
    end

    def run
      builder = Dsl.new
      builder.eval_gemfile(Bundler.default_gemfile)

      removed_dep = builder.remove_gem(@gem_name)

      # resolve to see if the after removing dep broke anything
      @definition = builder.to_definition(Bundler.default_lockfile, {})
      @definition.resolve_remotely!

      # since nothing broke, we can remove those gems from the gemfile
      remove_gem_from_gemfile

      # since we resolved successfully, write out the lockfile
      @definition.lock(Bundler.default_lockfile)

      # invalidate the cached Bundler.definition
      Bundler.reset_paths!

      Installer.install(Bundler.root, Bundler.definition)

      Bundler.ui.confirm "#{removed_dep.name}(#{removed_dep.requirement}) was removed."
    end

  private

    def remove_gem_from_gemfile
      lines = ""
      IO.readlines(Bundler.default_gemfile).map do |line|
        lines += line unless line =~ /gem "#{@gem_name}"/
      end

      File.open(Bundler.default_gemfile, "w") do |file|
        file.puts lines
      end
    end
  end
end
