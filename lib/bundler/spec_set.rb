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
        name = dep.respond_to?(:name) ? dep.name : dep
        current = lookup[name].first
        append_subgraph(specs, current, skip)
      end

      SpecSet.new(sorted.select { |s| specs[s.name] })
    end

    def valid_for?(deps)
      deps = deps.dup
      until deps.empty?
        specs = lookup[deps.shift.name]
        return false unless specs.any?
        specs.each { |s| deps.concat s.dependencies }
      end
      true
    end

    def to_a
      sorted.dup
    end

    def delete_if(&blk)
      @lookup = nil
      @sorted = nil
      @specs.delete_if(&blk)
    end

    def __materialize__(type)
      materialized = @specs.map do |s|
        next s unless s.is_a?(LazySpecification)
        s.__materialize__(s.source.send(type))
      end
      SpecSet.new(materialized)
    end

  private

    def append_subgraph(specs, current, skip)
      return unless current
      return if specs[current.name] || skip.include?(current.name)
      specs[current.name] = true
      current.dependencies.each do |dep|
        next if dep.type == :development
        s = lookup[dep.name].first
        append_subgraph(specs, s, skip)
      end
    end

    def sorted
      rake = @specs.find { |s| s.name == 'rake' }
      @sorted ||= ([rake] + tsort).compact.uniq
    end

    def lookup
      @lookup ||= begin
        lookup = Hash.new { |h,k| h[k] = [] }
        @specs.each do |s|
          lookup[s.name] << s
        end
        lookup
      end
    end

    def tsort_each_node
      @specs.each { |s| yield s }
    end

    def tsort_each_child(s)
      s.dependencies.sort_by { |d| d.name }.each do |d|
        next if d.type == :development
        lookup[d.name].each { |s| yield s }
      end
    end
  end
end