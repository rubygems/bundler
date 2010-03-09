require 'erb'

module Bundler
  class Environment
    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

  private

    def group_specs(specs)
      dependencies.each do |d|
        spec = specs.find { |s| s.name == d.name }
        group_spec(specs, spec, d.groups)
      end
      specs
    end

    def group_spec(specs, spec, groups)
      spec.groups.concat(groups)
      spec.groups.uniq!
      spec.dependencies.select { |d| d.type != :development }.each do |d|
        spec = specs.find { |s| s.name == d.name }
        group_spec(specs, spec, groups)
      end
    end
  end
end
