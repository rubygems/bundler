# frozen_string_literal: true
require "set"

module Bundler
  class SourceList
    attr_reader :path_sources,
      :git_sources,
      :global_rubygems_source

    def initialize
      @path_sources           = []
      @git_sources            = []
      @global_rubygems_source = nil
      @rubygems_local         = Source::Rubygems.new
      @rubygems_sources       = []
    end

    def add_path_source(options = {})
      add_source_to_list Source::Path.new(options), path_sources
    end

    def add_git_source(options = {})
      source = add_source_to_list(Source::Git.new(options), git_sources)
      warn_on_git_protocol(source)
      source
    end

    def add_rubygems_source(options = {})
      add_source_to_list Source::Rubygems.new(options), @rubygems_sources
    end

    def global_rubygems_remote=(uri)
      @global_rubygems_source = Source::Rubygems.new("remotes" => uri)
    end

    def default_source
      @global_rubygems_source || @rubygems_local
    end

    def rubygems_sources
      @rubygems_sources + [default_source]
    end

    def rubygems_remotes
      rubygems_sources.map(&:remotes).flatten.uniq
    end

    def all_sources
      path_sources + git_sources + rubygems_sources
    end

    def lock_sources
      rubygems_sources.sort_by(&:to_s) + git_sources.sort_by(&:to_s) + path_sources.sort_by(&:to_s)
    end

    def get(source)
      return unless source
      source_list_for(source).find {|s| source == s }
    end

    def replace_sources!(replacement_sources)
      return true if replacement_sources.empty?

      [path_sources, git_sources].each do |source_list|
        source_list.map! do |source|
          replacement_sources.find {|s| s == source } || source
        end
      end

      replacement_rubygems =
        replacement_sources.detect {|s| s.is_a?(Source::Rubygems) }
      @rubygems_aggregate = replacement_rubygems if replacement_rubygems

      # Return true if there were changes
      lock_sources.to_set != replacement_sources.to_set ||
        rubygems_remotes.to_set != replacement_rubygems.remotes.to_set
    end

    def cached!
      all_sources.each(&:cached!)
    end

    def remote!
      all_sources.each(&:remote!)
    end

  private

    def add_source_to_list(source, list)
      list.unshift(source).uniq!
      source
    end

    def source_list_for(source)
      case source
      when Source::Git      then git_sources
      when Source::Path     then path_sources
      when Source::Rubygems then rubygems_sources
      else raise ArgumentError, "Invalid source: #{source.inspect}"
      end
    end

    def combine_rubygems_sources
      Source::Rubygems.new("remotes" => rubygems_remotes)
    end

    def warn_on_git_protocol(source)
      return if Bundler.settings["git.allow_insecure"]

      if source.uri =~ /^git\:/
        Bundler.ui.warn "The git source `#{source.uri}` uses the `git` protocol, " \
          "which transmits data without encryption. Disable this warning with " \
          "`bundle config git.allow_insecure true`, or switch to the `https` " \
          "protocol to keep your data secure."
      end
    end
  end
end
