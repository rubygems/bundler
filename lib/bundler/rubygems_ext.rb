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

    alias_method :old_dependencies, :dependencies

    def dependencies
      original = old_dependencies
      original << Dependency.new("rake", ">= 0") if extensions.any? { |e| e =~ /rakefile|mkrf_conf/i }
      original
    end
  end

  class Dependency
    attr_accessor :source, :groups
  end
end
