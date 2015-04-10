module Bundler
  class Fetcher
    class CompactGemList
      require_relative 'compact_gem_list/cache.rb'
      require_relative 'compact_gem_list/updater.rb'

      attr_reader :fetcher, :directory

      def initialize(fetcher, directory)
        @fetcher = fetcher
        @directory = Pathname(directory)
        FileUtils.mkdir_p(@directory)
        @updater = Updater.new(@fetcher)
        @cache   = Cache.new(@directory)
      end

      def names
        @updater.update([[@cache.names_path, url('names.list')]])
        @cache.names
      end

      def versions
        @updater.update([[@cache.versions_path, url('versions.list')]])
        @cache.versions
      end

      def dependencies(names)
        @updater.update(names.map do |name|
          raise "Not string (#{name.inspect})" unless name.is_a?(String)
          [@cache.dependencies_path(name), url("info/#{name}")]
        end)
        names.map do |name|
          @cache.dependencies(name).map { |d| d.unshift(name) }
        end.flatten(1)
      end

      def spec(name, version, platform = nil)
        specific_dependency(name, version, platform)
      end

      private

      def url(path)
        ['api/v2', path].compact.join("/")
      end
    end
  end
end
