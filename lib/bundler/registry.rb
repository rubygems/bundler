module Bundler
  class Registry
    def initialize
      @items = {}
    end

    # Register a key
    #
    # If a key with the given name already exists, it is overwritten.
    def register(key, &block)
      raise ArgumentError, "block required" unless block_given?
      @items[key] = block
    end

    # Register a key for a hook
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
      return nil unless @items.key?(key)
      @items[key].call
    end
    alias_method :[], :get

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
    # registry.
    def merge(other)
      self.class.new.tap do |result|
        result.merge!(self)
        result.merge!(other)
      end
    end

    # Like #{merge} but merges into self.
    def merge!(other)
      @items.merge!(other.all)
      self
    end
  end
end
