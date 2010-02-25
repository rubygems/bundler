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

    module ImplicitRakeDependency
      def dependencies
        original = super
        original << Dependency.new("rake", ">= 0") if implicit_rake_dependency?
        original
      end

      private
        def implicit_rake_dependency?
          extensions.any? { |e| e =~ /rakefile|mkrf_conf/i }
        end
    end
    include ImplicitRakeDependency
  end

  class Dependency
    attr_accessor :source, :groups
  end
end
