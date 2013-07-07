require 'bundler/gem_helpers'

module Bundler
  module MatchPlatform
    include GemHelpers

    def match_platform(p)
      Gem::Platform::RUBY == platform or
      platform.nil? or p == platform or
      generic(Gem::Platform.new(platform)) == p or
      Gem::Platform.new(platform) === p
    end
    
    #If platform is dalvik we allow to specify a lower version than
    #the one the gem has
    def self.match_dalvik(current, p)
      return false if p.class != current.class 
      # cpu
      (current.cpu == 'universal' or p.cpu == 'universal' or current.cpu == p.cpu) and
  
      # os
      current.os == p.os and
  
      # version
      (current.version.nil? or p.version.nil? or current.version.to_i <= p.version.to_i)
    end
    
    #Match platform used when --platform is used
    def self.match_argument_platform(p)
      return false unless Bundler.settings[:platform]
      platform = Dependency.gem_platform(Bundler.settings[:platform].to_sym)
      if platform.os == 'dalvik'
        platform = Dependency.dalvik_platform(Bundler.settings[:platform].to_sym)
        Gem::Platform::RUBY == p or
        p.nil? or match_dalvik(platform, p) or
        match_dalvik(platform, Gem::Platform.new(p))                
      else  
        Gem::Platform::RUBY == p or
        p.nil? or p == platform or
        Gem::Platform.new(p) === platform        
      end     
    end
  end
end
