class Mirror < Struct.new(:uri, :fallback_timeout)
end

class Mirrors
  def initialize
    @mirrors = Hash.new { |h, k| h[k] = Mirror.new }
  end

  def [](key)
    @mirrors[key]
  end

  def fetch(key, &block)
    @mirrors.fetch(key, &block)
  end

  def to_h
    @mirrors
  end
end
