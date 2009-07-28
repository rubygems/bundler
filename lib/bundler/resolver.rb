module Bundler

  class Resolver
    def self.resolve(requirements, index = Gem.source_index)
      result = catch(:success) do
        new(index).resolve(requirements, {})
      end
      result && result.values
    end

    def initialize(index)
      @index = index
    end

    def resolve(reqs, activated)
      return activated if reqs.empty?

      reqs = reqs.sort_by {|dep| @index.search(dep).size }
      activated = activated.dup
      current   = reqs.shift

      if existing = activated[current.name]
        if current.version_requirements.satisfied_by?(existing.version)
          resolve(reqs, activated)
        end
      else
        specs = @index.search(current)
        specs.reverse!
        specs.each do |spec|
          activated[spec.name] = spec
          new_reqs = reqs + spec.dependencies.select do |d|
            d.type != :development
          end
          retval = resolve(new_reqs, activated)
          throw :success, retval if retval
        end
        nil
      end
    end
  end
end