module Bundler
  class SourceList
    attr_reader :path_sources,
                :git_sources,
                :rubygems_source

    def initialize
      @path_sources    = []
      @git_sources     = []
      @rubygems_source = Source::Rubygems.new
    end

    def add_path_source(options = {})
      add_source_to_list Source::Path.new(options), path_sources
    end

    def add_git_source(options = {})
      add_source_to_list Source::Git.new(options), git_sources
    end

    def add_rubygems_remote(uri)
      @rubygems_source.add_remote(uri)
      @rubygems_source
    end

    def all_sources
      path_sources + git_sources << rubygems_source
    end

    def get(source)
      if source.is_a?(Source::Rubygems)
        rubygems_source
      else
        source_list_for(source).find { |s| source == s }
      end
    end

    def replace_sources!(replacement_sources)
      [path_sources, git_sources].each do |source_list|
        source_list.map! do |source|
          replacement_sources.find { |s| s == source } || source
        end
      end
      @rubygems_source = replacement_sources.find { |s| s == rubygems_source } || rubygems_source
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
      when Source::Git  then git_sources
      when Source::Path then path_sources
      else raise ArgumentError, "Invalid source: #{source.inspect}"
      end
    end
  end
end
