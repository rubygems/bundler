require 'tsort'

module Bundler
  class SpecSet
    include TSort, Enumerable

    def initialize(specs)
      @specs  = specs.sort_by { |s| s.name }
      @lookup = Hash.new do |h,k|
        h[k] = specs.find { |s| s.name == k }
      end
      @sorted = ([@lookup['rake']] + tsort).compact.uniq
    end

    def each
      @sorted.each { |s| yield s }
    end

    def length
      @specs.length
    end

    def tsort_each_node
      @specs.each { |s| yield s }
    end

    def tsort_each_child(s)
      s.dependencies.sort_by { |d| d.name }.each do |d|
        next if d.type == :development
        yield @lookup[d.name]
      end
    end
  end
end