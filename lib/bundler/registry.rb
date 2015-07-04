module Bundler
  class Registry
    def initialize
      @items = {}
      @results_cache = {}

    end

    # Register a key with a lazy-loaded value.
    #
    # If a key with the given name already exists, it is overwritten.
    def register(key, &block)
      raise ArgumentError, "block required" if !block_given?
      @items[key] = block
    end

    # Register a key with a lazy-loaded value.
    #
    # If a key with the given name already exists, it is overwritten.
    def register_hook(key, object)
      @items[key] ||= []
      (@items[key] << object).uniq
    end

    # Get a value by the given key.
    #
    # This will evaluate the block given to `register` and return the
    # resulting value.
    def get(key)
      return nil if !@items.key?(key)
      return @results_cache[key] if @results_cache.key?(key)
      @results_cache[key] = @items[key].call
    end
    alias :[] :get

    # Returns all items in the registry
    #
    def all
      @items
    end
    # Checks if the given key is registered with the registry.
    #
    # @return [Boolean]
    def key?(key)
      @items.key?(key)
    end
    alias_method :has_key?, :key?
    # Merge one registry with another and return a completely new
    # registry. Note that the result cache is completely busted, so
    # any gets on the new registry will result in a cache miss.
    def merge(other)
      self.class.new.tap do |result|
        result.merge!(self)
        result.merge!(other)
      end
    end

    # Like #{merge} but merges into self.
    def merge!(other)
      @items.merge!(other.__internal_state[:items])
      self
    end

    def __internal_state
      {
        items: @items,
        results_cache: @results_cache
      }
    end

  end
end
