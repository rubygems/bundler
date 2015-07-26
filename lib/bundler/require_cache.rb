require 'set'
require 'digest/md5'
require 'tmpdir'
require 'pathname'
require 'bundler'

module Bundler
  class RequireCache
    CACHE_VERSION = '1'
    LEADING_SLASH = /^\//

    DL_EXTENSIONS = [
      RbConfig::CONFIG['DLEXT'],
      RbConfig::CONFIG['DLEXT2'],
    ].reject(&:empty?).map { |ext| ".#{ext}"}

    NORMALIZED_SYSTEM_EXTENSION = '.so'.freeze
    RUBY_EXTENSION = '.rb'.freeze
    SYSTEM_EXTENSIONS = /#{Regexp.union(DL_EXTENSIONS)}\z/
    QUALIFIED_NAME = /\.(rb|so|o|bundle|dylib)\z/

    CACHE_EXTENSIONS = [RUBY_EXTENSION, NORMALIZED_SYSTEM_EXTENSION]
    LOAD_PATH_EXTENSIONS = [RUBY_EXTENSION, *DL_EXTENSIONS]

    RUBY_FILES = "**/*#{RUBY_EXTENSION}"
    DL_FILES = "**/*{#{DL_EXTENSIONS.join(',')}}"

    attr_reader :load_paths

    def initialize(load_paths)
      @load_paths = (load_paths + $LOAD_PATH).uniq
      @initial_load_path = $LOAD_PATH.to_set
      load_cache || build_and_dump
    end

    def [](path)
      lookup_load_path(path) || lookup_cache(path)
    end

    private

      def lookup_load_path(path)
        possible_names = compute_possible_names(path, LOAD_PATH_EXTENSIONS)

        dynamic_load_path.each do |load_path|
          possible_names.each do |name|
            absolute_path = File.join(load_path, name)
            return absolute_path if File.exists?(absolute_path)
          end
        end
        nil
      end

      def lookup_cache(path)
        possible_names = compute_possible_names(path, CACHE_EXTENSIONS)
        possible_names.each do |name|
          absolute_path = @cache[name]
          return absolute_path if absolute_path
        end
        nil
      end

      def compute_possible_names(path, possible_extensions)
        path = normalize_system_extension_path(path.to_s)
        return [path] if path =~ QUALIFIED_NAME
        possible_extensions.map { |ext| "#{path}#{ext}" }
      end

      def dynamic_load_path
        $LOAD_PATH.reject { |path| @initial_load_path.include?(path) }
      end

      def build_and_dump
        @cache = build
        dump
      end

      def dump
        File.open(cache_path.to_s, 'wb+') { |f| f.write(Marshal.dump(@cache)) }
      end

      def load_cache
        return unless cache_path.exist?
        @cache = Marshal.load(cache_path.read)
      end

      def build
        cache = {}
        each_file_in_load_paths(RUBY_FILES) do |relative_path, absolute_path|
          cache[relative_path] ||= absolute_path
        end
        each_file_in_load_paths(DL_FILES) do |relative_path, absolute_path|
          cache[normalize_system_extension_path(relative_path)] ||= absolute_path
        end
        cache
      end

      def each_file_in_load_paths(pattern, &block)
        load_paths.each do |load_path|
          Dir["#{load_path}/#{pattern}"].each do |absolute_path|
            relative_path = relativise_path(absolute_path, load_path)
            yield relative_path, absolute_path
          end
        end
      end

      def relativise_path(path, directory)
        path = path.sub(directory, '')
        path.sub!(LEADING_SLASH, '')
      end

      def normalize_system_extension_path(path)
        path.sub(SYSTEM_EXTENSIONS, NORMALIZED_SYSTEM_EXTENSION)
      end

      def cache_path
        @cache_path ||= Pathname.new(Dir::tmpdir).join("bundler-cache-#{CACHE_VERSION}-#{cache_key}.marshal")
      end

      def cache_key
        Digest::MD5.hexdigest(load_paths.join(':'))
      end
  end
end
