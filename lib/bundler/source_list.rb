module Bundler
  class SourceList
    attr_reader :path_sources,
                :git_sources,
                :svn_sources,
                :rubygems_sources,
                :rubygems_aggregate

    def initialize
      @path_sources       = []
      @git_sources        = []
      @svn_sources        = []
      @rubygems_aggregate = Source::Rubygems.new
      @rubygems_sources   = [@rubygems_aggregate]
    end

    def add_path_source(options = {})
      add_source_to_list Source::Path.new(options), path_sources
    end

    def add_git_source(options = {})
      add_source_to_list Source::Git.new(options), git_sources
    end

    def add_svn_source(options = {})
      add_source_to_list Source::SVN.new(options), svn_sources
    end

    def add_rubygems_source(options = {})
      add_source_to_list Source::Rubygems.new(options), @rubygems_sources
    end

    def add_rubygems_remote(uri)
      @rubygems_aggregate.add_remote(uri)
      @rubygems_aggregate
    end

    def all_sources
      path_sources + git_sources + svn_sources + rubygems_sources
    end

    def get(source)
      source_list_for(source).find { |s| source == s }
    end

    def lock_sources
      lock_sources = (path_sources + git_sources + svn_sources).sort_by(&:to_s)
      lock_sources << combine_rubygems_sources
    end

    def replace_sources!(replacement_sources)
      [path_sources, git_sources, svn_sources, rubygems_sources].each do |source_list|
        source_list.map! do |source|
          replacement_sources.find { |s| s == source } || source
        end
      end
    end

    def cached!
      all_sources.each(&:cached!)
    end

    def remote!
      all_sources.each(&:remote!)
    end

    def merge(source_list, base_path)
      source_list.path_sources.reverse.each do |source|
        options = source.options.dup
        options["path"] = source.path.expand_path(base_path.dirname).relative_path_from(Bundler.root)
        add_path_source(options)
      end

      merge_source_to_list(git_sources, source_list.git_sources)
      merge_source_to_list(svn_sources, source_list.svn_sources)

      rubygems_without_aggregate_sources = source_list.rubygems_sources.reject do |source|
        source.object_id == source_list.rubygems_aggregate.object_id
      end

      merge_source_to_list(rubygems_sources, rubygems_without_aggregate_sources)

      # TODO - figure out how to merge the aggregate source.
    end

  private

    def add_source_to_list(source, list)
      list.unshift(source).uniq!
      source
    end

    def merge_source_to_list(target_list, source_list)
      source_list.each do |source|
        add_source_to_list source, target_list
      end
    end

    def source_list_for(source)
      case source
      when Source::Git      then git_sources
      when Source::SVN      then svn_sources
      when Source::Path     then path_sources
      when Source::Rubygems then rubygems_sources
      else raise ArgumentError, "Invalid source: #{source.inspect}"
      end
    end

    def combine_rubygems_sources
      Source::Rubygems.new("remotes" => rubygems_sources.map(&:remotes).flatten.uniq.reverse)
    end
  end
end
