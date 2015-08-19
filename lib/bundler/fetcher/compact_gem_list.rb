module Bundler
  class Fetcher
    class CompactGemList
      require "set"

      autoload :Cache,   "bundler/fetcher/compact_gem_list/cache"
      autoload :Updater, "bundler/fetcher/compact_gem_list/updater"

      attr_reader :fetcher, :directory

      def initialize(fetcher, directory)
        @fetcher = fetcher
        @directory = Pathname(directory)
        FileUtils.mkdir_p(@directory)
        @updater = Updater.new(@fetcher)
        @cache   = Cache.new(@directory)
        @endpoints = Set.new
        @info_checksums_by_name = {}
      end

      def names
        update([[@cache.names_path, "names"]])
        @cache.names
      end

      def versions
        update([[@cache.versions_path, "versions"]])
        versions, @info_checksums_by_name = @cache.versions
        versions
      end

      def dependencies(names)
        names.each {|n| update_info(n) }
        names.flat_map do |name|
          @cache.dependencies(name).map {|d| d.unshift(name) }
        end
      end

      def spec(name, version, platform = nil)
        update_info(name)
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

      def update_info(name)
        path = @cache.dependencies_path(name)
        return if @info_checksums_by_name[name] == @updater.checksum_for_file(path)
        update([[path, "info/#{name}"]])
      end

      def url(path)
        path
      end
    end
  end
end
