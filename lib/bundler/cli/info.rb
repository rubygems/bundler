# frozen_string_literal: true

module Bundler
  class CLI::Info
    attr_reader :gem_name, :options
    def initialize(options, gem_name)
      @options = options
      @gem_name = gem_name
    end

    def run
      spec = spec_for_gem(gem_name)

      spec_not_found(gem_name) unless spec
      return print_gem_path(spec) if @options[:path]
      print_gem_info(spec)
      print_gem_dependencies(gem_name)
    end

  private

    def spec_for_gem(gem_name)
      spec = Bundler.definition.specs.find {|s| s.name == gem_name }
      spec || default_gem_spec(gem_name)
    end

    def default_gem_spec(gem_name)
      return unless Gem::Specification.respond_to?(:find_all_by_name)
      gem_spec = Gem::Specification.find_all_by_name(gem_name).last
      return gem_spec if gem_spec && gem_spec.respond_to?(:default_gem?) && gem_spec.default_gem?
    end

    def spec_not_found(gem_name)
      raise GemNotFound, Bundler::CLI::Common.gem_not_found_message(gem_name, Bundler.definition.dependencies)
    end

    def print_gem_path(spec)
      Bundler.ui.info spec.full_gem_path
    end

    def print_gem_info(spec)
      gem_info = String.new
      gem_info << "  * #{spec.name} (#{spec.version}#{spec.git_version})\n"
      gem_info << "\tSummary: #{spec.summary}\n" if spec.summary
      gem_info << "\tHomepage: #{spec.homepage}\n" if spec.homepage
      gem_info << "\tPath: #{spec.full_gem_path}\n"
      gem_info << "\tDefault Gem: yes" if spec.respond_to?(:default_gem?) && spec.default_gem?
      Bundler.ui.info gem_info
    end

    def print_gem_dependencies(spec)
      top_level_dependencies = summarize(spec)

      stat_info = String.new
      stat_info << "\tDependents:\n"
      if top_level_dependencies.count > 0
        top_level_dependencies.each do |stat_line|
          stat_info << format("\t\t%s (%s)\n", stat_line[:name], stat_line[:version])
        end
      else
        stat_info << "\t\tNone"
      end

      Bundler.ui.info stat_info
    end

    def summarize(spec)
      definition = Bundler.definition
      lockfile_contents = definition.to_lock
      parser = Bundler::LockfileParser.new(lockfile_contents)
      @tree = specs_as_tree(parser.specs)

      reverse_dependencies_with_versions(spec)
    end

    def specs_as_tree(specs)
      specs.inject({}) do |hash, spec|
        hash[spec.name] = spec
        hash
      end
    end

    def transitive_dependencies(target)
      raise ArgumentError, "Unknown gem #{target}" unless @tree.key? target

      top_level = @tree[target].dependencies
      all_level = top_level + top_level.inject([]) do |arr, dep|
        next arr if dep.name == "bundler"

        arr + transitive_dependencies(dep.name)
      end

      all_level.uniq(&:name)
    end

    def reverse_dependencies_with_versions(target)
      @tree.map do |name, dep|
        transitive_dependencies(name).map do |transitive_dependency|
          next unless transitive_dependency.name == target
          {
            :name => dep.name,
            :version => transitive_dependency.requirement.to_s,
            :requirement => transitive_dependency.requirement,
          }
        end
      end.flatten.compact.sort do |a, b|
        a[:requirement].as_list <=> b[:requirement].as_list
      end
    end
  end
end
