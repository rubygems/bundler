class Module
  def autoload_with_cache(const, path)
    autoload_without_cache(const, Bundler.load.require_cache[path] || path)
  end

  alias_method :autoload_without_cache, :autoload
  alias_method :autoload, :autoload_with_cache
end

class << Kernel
  def require_with_cache(path)
    require_without_cache(Bundler.load.require_cache[path] || path)
  end

  alias_method :require_without_cache, :require
  alias_method :require, :require_with_cache
end

module Kernel
  def require_with_cache(path)
    require_without_cache(Bundler.load.require_cache[path] || path)
  end

  alias_method :require_without_cache, :require
  alias_method :require, :require_with_cache

  def autoload_with_cache(const, path)
    STDERR.puts "WARNING: Top level autoload is not properly supported yet, #{const} was eager loaded"
    require(path)
  end

  alias_method :autoload_without_cache, :autoload
  alias_method :autoload, :autoload_with_cache
end
