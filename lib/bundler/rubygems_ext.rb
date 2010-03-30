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
      Dir.chdir(full_gem_path) do
        rev = `git rev-parse HEAD`.strip[0...6]
        branch = `git show-branch --no-color 2>/dev/null`.strip[/\[(.*?)\]/, 1]
        branch.empty? ? " #{rev}" : " #{branch}-#{rev}"
      end if File.exist?(File.join(full_gem_path, ".git"))
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

    alias :to_yaml_properties_before_crazy to_yaml_properties

    def to_yaml_properties
      to_yaml_properties_before_crazy.reject { |p| ["@source", "@groups"].include?(p.to_s) }
    end
  end
end
