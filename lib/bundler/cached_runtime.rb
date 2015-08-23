require 'bundler/runtime'
require 'bundler/require_cache'

module Bundler
  class CachedRuntime < Runtime
    class << self
      attr_accessor :blacklist
    end
    self.blacklist = []

    def setup(*)
      super
      require_relative 'require_patch'
      self
    end

    def require_cache
      @require_cache ||= RequireCache.new(@load_paths)
    end

    private
      def register_load_paths(spec)
        super if self.class.blacklist.include?(spec.name)
        @load_paths ||= []
        @load_paths += spec.load_paths
        @require_cache = nil
      end
  end
end
