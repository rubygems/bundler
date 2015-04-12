module Bundler
  class Fetcher
    class CompactGemList
      require 'set'

      require_relative 'compact_gem_list/cache.rb'
      require_relative 'compact_gem_list/updater.rb'

      attr_reader :fetcher, :directory

      def initialize(fetcher, directory)
        @fetcher = fetcher
        @directory = Pathname(directory)
        FileUtils.mkdir_p(@directory)
        @updater = Updater.new(@fetcher)
        @cache   = Cache.new(@directory)
        @endpoints = Set.new
      end

      def names
        update([[@cache.names_path, 'names']])
        @cache.names
      end

      def versions
        update([[@cache.versions_path, 'versions']])
        @cache.versions
      end

      def dependencies(names)
        update(names.map do |name|
          [@cache.dependencies_path(name), "info/#{name}"]
        end)
        names.map do |name|
          @cache.dependencies(name).map { |d| d.unshift(name) }
        end.flatten(1)
      end

      def spec(name, version, platform = nil)
        update([[@cache.dependencies_path(name), "info/#{name}"]])
        @cache.specific_dependency(name, version, platform)
      end

      private

      def update(files)
        files.each do |path, remote_path|
          next if @endpoints.include?(remote_path)
          @updater.update [[path, url(remote_path)]]
          @endpoints << remote_path
        end
      end

      def url(path)
        path
      end
    end
  end
end
