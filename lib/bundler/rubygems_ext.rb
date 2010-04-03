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

    def git_version
      if @loaded_from && File.exist?(File.join(full_gem_path, ".git"))
        rev = Dir.chdir(full_gem_path){ `git rev-parse HEAD`.strip }
        branch = full_gem_path.split("-")[3]
        branch ? " #{branch}-#{rev[0...6]}" : " #{rev[0...6]}"
      end
    end

    def to_gemfile(path = nil)
      gemfile = "source :gemcutter\n"
      gemfile << dependencies_to_gemfile(dependencies)
      gemfile << dependencies_to_gemfile(development_dependencies, :development)
    end

  private

    def dependencies_to_gemfile(dependencies, group = nil)
      gemfile = ''
      if dependencies.any?
        gemfile << "group #{group} do\n" if group
        dependencies.each do |dependency|
          gemfile << '  ' if group
          gemfile << %|gem "#{dependency.name}"|
          req = dependency.requirements_list.first
          gemfile << %|, "#{req}"| if req
          gemfile << "\n"
        end
        gemfile << "end\n" if group
      end
      gemfile
    end

  end

  class Dependency
    attr_accessor :source, :groups

    def to_yaml_properties
      instance_variables.reject { |p| ["@source", "@groups"].include?(p.to_s) }
    end
  end
end
