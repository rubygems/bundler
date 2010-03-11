require 'erb'

module Bundler
  class Environment
    attr_reader :root

    def initialize(root, definition)
      @root = root
      @definition = definition
    end

    def index
      @index ||= Index.build do |idx|
        idx.use runtime_gems
        idx.use Index.cached_gems
      end
    end

  private

    def runtime_gems
      @runtime_gems ||= Index.build do |i|
        sources.each do |s|
          i.use s.local_specs if s.respond_to?(:local_specs)
        end

        i.use Index.installed_gems
      end
    end

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
