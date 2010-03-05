unless defined? Gem
  require 'rubygems'
  require 'rubygems/specification'
end

module Gem
  @loaded_stacks = Hash.new { |h,k| h[k] = [] }

  class Specification
    attr_accessor :source, :location

    def load_paths
      require_paths.map {|p| File.join(full_gem_path, p) }
    end

    def groups
      @groups ||= []
    end

    def bundler_dependencies
      original = dependencies
      original << Dependency.new("rake", ">= 0") if implicit_rake_dependency?
      original
    end

  private

    def implicit_rake_dependency?
      extensions.any? { |e| e =~ /rakefile|mkrf_conf/i }
    end
  end

  class Dependency
    attr_accessor :source, :groups

    alias :to_yaml_properties_before_crazy to_yaml_properties

    def to_yaml_properties
      to_yaml_properties_before_crazy.reject { |p| ["@source", "@groups"].include?(p.to_s) }
    end
  end
end
