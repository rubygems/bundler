# frozen_string_literal: true
module Bundler
  module CLI::Pristine
    class ConflictingGems < PristineError; end
    class AmbiguousOption < PristineError; end
    attr_reader :options, :gem_list
    def initialize(options, gem_list)
      @options = options
      @gem_list = gem_list
    end

    def run
      # Determine if -extensions and --no-extensions or  are conflict
      if options["extensions"] && options["no-extensions"]
        Bundler.ui.error "You can't use --extensions and --no-extensions at the same time"
        raise AmbiguousOption
      end

      # Raise error when Gemfile is not present
      definition = begin
        Bundler.definition
      rescue GemfileNotFound
        Bundler.ui.error "You can't pristine without a Gemfile. Please consider add Gemfile then run `bundle install` before pristine"
        raise
      end
      # Raise error when lockfile is not present
      unless Bundler.default_lockfile.exist?
        Bundler.ui.error "You can't pristine without a Gemfile.lock. Please consider run `bundle install` before pristine"
        raise GemfileLockNotFound, "Could not locate Gemfile.lock"
      end

      # Find the path gems and exclude them from calling gem pristine
      path_gems, git_gems, pristine_gems = []
      skip_gems = options[:skip]
      # If gem list is empty, we need to add everything to pristine_gems, else it equals
      if gem_list.empty?
        pristine_gems = definition.calculate_full_gem_list
      else
        unless skip_gems.empty?
          # Determine if there are any conflict groups
          check_conflicting(gem_list, skip_gems)
          pristine_gems = gem_list - skip_gems
        end
      end

      if definition.any_path_sources?

      end
      # Find git sources gems and
      git_sources = definition.git_sources if definition.any_git_sources?
    end

  private

    # This method is used to compute what are the gems
    def compute_gem_list(definition)
      gem_list = definition if @gem_list.empty?
    end

    def check_conflicting(gem_list, skip_gems)
      conflicting_gems = skip_gems & gem_list
      unless conflicting_gems.empty?
        Bundler.ui.error "You can't list a gem in both GEMLIST and --skip." \
          "The offending gems are: #{conflicting_gems.join(", ")}."
        raise ConflictingGems
      end
    end
  end
end
