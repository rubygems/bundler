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

    # TODO: Handle platform filtering
    def for(deps, skip = [])
      specs = {}
      deps.each do |dep|
        current = lookup[dep.respond_to?(:name) ? dep.name : dep]
        append_subgraph(specs, current, skip)
      end

      SpecSet.new(sorted.select { |s| specs[s.name] })
    end

    def to_a
      sorted.dup
    end

    def __materialize__
      @lookup = nil
      @specs.map! do |s|
        next s unless s.is_a?(LazySpecification)
        yield s
      end
    end

  private

    def append_subgraph(specs, current, skip)
      return if specs[current.name] || skip.include?(current.name)
      specs[current.name] = true
      current.dependencies.each do |dep|
        next if dep.type == :development
        append_subgraph(specs, lookup[dep.name], skip)
      end
    end

    def sorted
      rake = @specs.find { |s| s.name == 'rake' }
      @sorted ||= ([rake] + tsort).compact.uniq
    end

    def lookup
      @lookup ||= Hash.new do |h,k|
        v = @specs.find { |s| s.name == k }
        raise InvalidSpecSet, "SpecSet is missing '#{k}'" unless v
        h[k] = v
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