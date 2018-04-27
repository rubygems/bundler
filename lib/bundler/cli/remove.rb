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

      # store removed gems to display on successfull removal
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

      # TODO: Discuss about using this,
      # currently gems are not removed from .bundle
      # Installer.install(Bundler.root, Bundler.definition)

      display_removed_gems
    end

  private

    def remove_gems_from_gemfile
      # store patterns of all gems to be removed
      patterns = []
      @gems.each do |g|
        patterns << /gem "#{g}"/
      end

      # create a union of patterns to match any of them
      re = Regexp.union(patterns)

      lines = ""
      group = false
      whole_group = ""
      inside_group = ""
      IO.readlines(Bundler.default_gemfile).map do |line|
        group = true if line =~ /group /

        lines += line if !line.match(re) && !group

        next unless group
        whole_group += line unless line.match(re)

        if line =~ /end/
          group = false
        elsif line !~ /group /
          inside_group += line unless line.match(re)
        end

        if inside_group =~ /gem / && !group
          lines += whole_group
          inside_group = ""
          whole_group = ""
        end
      end

      File.open(Bundler.default_gemfile, "w") do |file|
        file.puts lines
      end
    end

    def display_removed_gems
      @removed_deps.each do |dep|
        Bundler.ui.confirm "#{dep.name}(#{dep.requirement}) was removed."
      end
    end
  end
end
