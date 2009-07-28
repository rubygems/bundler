# Extending Gem classes to add necessary tracking information
module Gem
  class Dependency
    attr_accessor :required_by
  end
  class Specification
    attr_accessor :required_by
  end
end

module Bundler

  class Resolver
    def self.resolve(requirements, index = Gem.source_index)
      result = catch(:success) do
        resolver = new(index)
        resolver.resolve(requirements, {})
        nil
      end
      result && result.values
    end

    def initialize(index)
      @index = index
    end

    def resolve(reqs, activated)
      throw :success, activated if reqs.empty?

      reqs = reqs.sort_by {|dep| @index.search(dep).size }
      activated = activated.dup
      current   = reqs.shift

      if existing = activated[current.name]
        if current.version_requirements.satisfied_by?(existing.version)
          resolve(reqs, activated)
        else
          throw current.required_by ? current.required_by.name : existing.required_by.name
        end
      else
        @index.search(current).reverse_each do |spec|
          resolve_requirement(spec, current, reqs.dup, activated.dup)
        end
      end
    end

    def resolve_requirement(spec, requirement, reqs, activated)
      spec.required_by     = requirement
      activated[spec.name] = spec

      spec.dependencies.each do |dep|
        next if dep.type == :development
        dep.required_by = requirement
        reqs << dep
      end

      catch(requirement.name) do
        resolve(reqs, activated)
      end
    end

  end
end