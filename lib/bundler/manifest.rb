module Bundler
  class Manifest
    attr_reader :sources, :dependencies
    
    def initialize(sources, dependencies)
      @sources, @dependencies = sources, dependencies
    end
  end
end