# Extending Gem classes to add necessary tracking information
module Gem
  class Dependency
    def required_by
      @required_by ||= []
    end
  end
  class Specification
    def required_by
      @required_by ||= []
    end
  end
end

module Bundler

  class Resolver

    attr_reader :errors

    def self.resolve(requirements, index = Gem.source_index)
      result = catch(:success) do
        resolver = new(index)
        resolver.resolve(requirements, {})
        nil
      end
      result && result.values
    end

    def initialize(index)
      @errors = {}
      @index  = index
    end

    def resolve(reqs, activated)
      throw :success, activated if reqs.empty?

      reqs = reqs.sort_by do |req|
        activated[req.name] ? 0 : @index.search(req).size
      end

      activated = activated.dup
      current   = reqs.shift

      if existing = activated[current.name]
        if current.version_requirements.satisfied_by?(existing.version)
          @errors.delete(existing.name)
          resolve(reqs, activated)
        else
          @errors[existing.name] = { :gem => existing, :requirement => current }
          parent = current.required_by.last || existing.required_by.last
          throw parent.name
        end
      else
        @index.search(current).reverse_each do |spec|
          resolve_requirement(spec, current, reqs.dup, activated.dup)
        end
      end
    end

    def resolve_requirement(spec, requirement, reqs, activated)
      spec.required_by.replace requirement.required_by
      activated[spec.name] = spec

      spec.dependencies.each do |dep|
        next if dep.type == :development
        dep.required_by << requirement
        reqs << dep
      end

      catch(requirement.name) do
        resolve(reqs, activated)
      end
    end

  end
end