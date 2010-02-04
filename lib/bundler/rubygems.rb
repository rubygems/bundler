require 'rubygems'
require 'rubygems/specification'

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
  end

  class Dependency
    attr_accessor :source, :groups
  end
end
