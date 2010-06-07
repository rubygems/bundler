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

    def for(dependencies, skip = [], check = false)
      handled, deps, specs = {}, dependencies.dup, []

      until deps.empty?
        dep = deps.shift
        next if handled[dep] || skip.include?(dep.name)

        spec = lookup[dep.name].find do |s|
          s.match_platform(dep.__platform)
        end

        handled[dep] = true

        if spec
          specs << spec

          spec.dependencies.each do |d|
            next if d.type == :development
            deps << DepProxy.new(d, dep.__platform)
          end
        elsif check
          return false
        end
      end

      check ? true : SpecSet.new(specs)
    end

    def valid_for?(deps)
      self.for(deps, [], true)
    end

    def [](key)
      key = key.name if key.respond_to?(:name)
      lookup[key].reverse
    end

    def to_a
      sorted.dup
    end

    def to_hash
      lookup.dup
    end

    def materialize(type, deps)
      materialized = self.for(deps, []).to_a
      materialized.map! do |s|
        next s unless s.is_a?(LazySpecification)
        s.__materialize__(s.source.send(type))
      end
      SpecSet.new(materialized)
    end

    def names
      lookup.keys
    end

    def select!(names)
      @lookup = nil
      @sorted = nil

      @specs.delete_if { |s| !names.include?(s.name) }
      self
    end

  private

    def sorted
      rake = @specs.find { |s| s.name == 'rake' }
      @sorted ||= ([rake] + tsort).compact.uniq
    end

    def lookup
      @lookup ||= begin
        lookup = Hash.new { |h,k| h[k] = [] }
        specs = @specs.sort_by do |s|
          s.platform.to_s == 'ruby' ? "\0" : s.platform.to_s
        end
        specs.reverse_each do |s|
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