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
      handled = {}
      deps = deps.map { |d| d.respond_to?(:name) ? d.name : d }

      until deps.empty?
        dep = deps.shift
        next if handled[dep] || skip.include?(dep)
        specs = lookup[dep]
        next if specs.empty?
        specs.each do |s|
          handled[s.name] = true
          s.dependencies.each  do |d|
            next if d.type == :development
            deps << d.name
          end
        end
      end

      SpecSet.new(sorted.select { |s| handled[s.name] })
    end

    def valid_for?(deps)
      deps = deps.dup
      handled = {}

      until deps.empty?
        dep = deps.shift
        unless dep.type == :development || handled[dep.name]
          specs = lookup[dep.name]
          return false unless specs.any?
          handled[dep.name] = true
          specs.each { |s| deps.concat s.dependencies }
        end
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

    def materialize(type, deps)
      materialized = @specs.map do |s|
        next s unless s.is_a?(LazySpecification)
        s.__materialize__(s.source.send(type))
      end
      SpecSet.new(materialized)
    end

  private

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