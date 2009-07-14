module Bundler
  class Dependency

    attr_reader :name, :version, :require_as, :environments

    def initialize(name, options = {})
      options.each do |k, v|
        options[k.to_s] = v
      end

      @name         = name
      @version      = options["version"]    || ">= 0"
      @require_as   = [ options["require_as"] || name ].flatten
      @environments = [ options["environments"] ].flatten.compact
    end
    
    def to_s
      to_gem_dependency.to_s
    end
    
    def to_gem_dependency
      @gem_dep ||= Gem::Dependency.new(name, version)
    end

  end
end