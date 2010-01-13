module Bubble
  class Specification
    attr_reader :full_gem_path

    def initialize(specification, full_gem_path)
      @specification = specification
      @full_gem_path = full_gem_path
    end

    def method_missing(meth, *args, &block)
      send(meth, *args, &block)
    end
  end
end