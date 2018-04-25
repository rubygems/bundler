# frozen_string_literal: true

module Bundler
  class CLI::Remove
    def initialize(gems)
      @gems = gems
      @removed_deps = []
    end

    def run
      builder = Dsl.new
      builder.eval_gemfile(Bundler.default_gemfile)

      @removed_deps = builder.remove_gems(@gems)

      # resolve to see if the after removing dep broke anything
      @definition = builder.to_definition(Bundler.default_lockfile, {})
      @definition.resolve_remotely!

      # since nothing broke, we can remove those gems from the gemfile
      remove_gems_from_gemfile

      # since we resolved successfully, write out the lockfile
      @definition.lock(Bundler.default_lockfile)

      # invalidate the cached Bundler.definition
      Bundler.reset_paths!

      # Todo: Discuss about using this
      # Installer.install(Bundler.root, Bundler.definition)

      print_success
    end

  private

    def remove_gems_from_gemfile
      lines = ""
      IO.readlines(Bundler.default_gemfile).map do |line|
        # Todo: Do this for all gems
        lines += line unless line =~ /gem "#{@gems[0]}"/
      end

      File.open(Bundler.default_gemfile, "w") do |file|
        file.puts lines
      end
    end

    def print_success
      @removed_deps.each do |dep|
        Bundler.ui.confirm "#{dep.name}(#{dep.requirement}) was removed."
      end
    end
  end
end
