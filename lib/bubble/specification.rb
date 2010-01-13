module Bubble
  class Specification < Gem::Specification
    def self.from_gemspec(gemspec)
      spec = allocate
      gemspec.instance_variables.each do |ivar|
        spec.instance_variable_set(ivar, gemspec.instance_variable_get(ivar))
      end
      spec
    end

    def full_gem_path
      @loaded_from.dirname.expand_path
    end
  end
end