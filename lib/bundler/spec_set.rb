require 'tsort'

module Bundler
  class SpecSet
    include TSort, Enumerable

    def initialize(specs)
      @specs = specs.sort_by { |s| s.name }
    end

    def each
      sorted.each { |s| yield s }
    end

    def length
      @specs.length
    end

    def for(*deps)
      specs = {}
      deps.flatten.each do |dep|
        current = lookup[dep.respond_to?(:name) ? dep.name : dep]
        append_subgraph(specs, current)
      end

      sorted.select { |s| specs[s.name] }
    end

    def to_a
      sorted.dup
    end

  private

    def append_subgraph(specs, current)
      return if specs[current.name]
      specs[current.name] = true
      current.dependencies.each do |dep|
        next if dep.type == :development
        append_subgraph(specs, lookup[dep.name])
      end
    end

    def sorted
      @sorted ||= ([lookup['rake']] + tsort).compact.uniq
    end

    def lookup
      @lookup ||= Hash.new do |h,k|
        h[k] = @specs.find { |s| s.name == k }
      end
    end

    def tsort_each_node
      @specs.each { |s| yield s }
    end

    def tsort_each_child(s)
      s.dependencies.sort_by { |d| d.name }.each do |d|
        next if d.type == :development
        yield lookup[d.name]
      end
    end
  end
end