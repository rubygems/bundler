# frozen_string_literal: true
require "bundler/cli/exec"
module Bundler
  class CLI::Pristine
    class ConflictingGems < PristineError
    end
    class AmbiguousOption < PristineError
    end
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
      # If gem list is empty, we need to add everything to pristine_gems, else we can use things from the gem_list
      if gem_list.empty?
        pristine_gems = definition.calculate_non_path_gem_list
        git_gems = definition.calculate_git_gems
        path_gems = definition.calculate_path_only_gems
        warn_path_gems(path_gems)
        pristine(pristine_gems, git_gems, true)
      else
        check_conflicting(gem_list, options[:skip])
        pristine(gem_list)
      end
    end

  private

    def check_conflicting(gem_list, skip_gems)
      conflicting_gems = skip_gems & gem_list
      return if conflicting_gems.empty?
      Bundler.ui.error "You can't list a gem in both GEMLIST and --skip." \
          "The offending gems are: #{conflicting_gems.join(", ")}."
      raise ConflictingGems
    end

    def pristine(gems, git_gems = nil, lazy_spec_provided = false)
      gem_list = lazy_spec_provided ? gems.map(&:name) : gems
      skip_gems = options[:skip]
      pristine_gems = compute_pristine_gems(gem_list, skip_gems)
      binding.pry
      pristine_gems.each do |gem|
        command = String.new("gem pristine #{gem}")
        command << " -v #{gem.version}" if lazy_spec_provided && gem.respond_to?(:version)
        command << " --extensions" if options["extensions"]
        command << " --no-extensions" if options["no-extensions"]
        CLI.start(command.split)
      end
      pristine_git_gems(git_gems)
    end

    def warn_path_gems(path_gems)
      # Warn about the path gems
      return if path_gems.empty?
      message = String.new
      message << "At this moment, Bundler cannot prstine the following gems:"
      path_gems.each do |gem|
        message << "* #{gem.name} at #{gem.source.path}"
      end
      Bundler.ui.warn(message)
    end

    def pristine_git_gems(gems)
      # Pristine git gems
    end

    def compute_pristine_gems(gems, skip_gems)
      if gems.is_a?(SpecSet)
        gems.reject {|gem| skip_gems.include? gem.name }
      else
        gems - skip_gems
      end
    end
  end
end
