require 'bundler/fetcher/dependency'

module Bundler
  class Fetcher
    class CompactDependency < Dependency
      def dependency_specs(gem_names)
        dependency_names = []
        specs = compact_gem_list.dependencies(gem_names).each do |spec|
          spec[1] = Gem::Version.new spec[1]
          dependency_names.concat spec[3].map! { |name, args| Gem::Dependency.new(name, args) }.map(&:name)
        end
        [specs, dependency_names]
      end

      def dependency_api_uri(gem_names = [])
        fetch_uri + "info"
      end

      private

      def compact_gem_list
        @compact_gem_list ||= begin
          uri_part = [display_uri.hostname, display_uri.port, Digest.hexencode(display_uri.path)].compact.join('.')
          CompactGemList.new(self, Bundler.cache + 'compact_index' + uri_part)
        end
      end
    end
  end
end
