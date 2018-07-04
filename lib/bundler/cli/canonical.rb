# frozen_string_literal: true

module Bundler
  class CLI::Canonical
    def initialize(options)
      @options = options
    end

    def run
      definition = Bundler.definition
      @resolve = definition.resolve

      gemfile = []
      Array(definition.send(:sources).global_rubygems_source).each do |s|
        s.remotes.each {|r| gemfile << "source #{r.to_s.dump}" }
      end

      gemfile << nil

      definition.dependencies.group_by(&:groups).each_key(&:sort!).sort_by(&:first).each do |groups, deps|
        groups = nil if groups.empty? || groups.include?(:default)

        gemfile << "group #{groups.map(&:inspect).uniq.join(", ")} do" if groups
        gemfile << deps_contents(deps.sort_by(&:name), !groups.nil?, true)
        gemfile << "end" if groups
        gemfile << nil
      end

      contents = gemfile.join("\n").gsub(/\n{3,}/, "\n\n").strip

      if @options[:view]
        puts contents
      else
        SharedHelpers.write_to_gemfile(Bundler.default_gemfile, contents)
      end
    end

  private

    # @param [[Bundler::Dependency]] deps        Array of dependency instances of gems
    # @param [Boolean]               inside_group Whether gems to be shown are inside group
    # @param [Boolean]               show_summary Whether summary for the gems is to be shown
    def deps_contents(deps, inside_group = false, show_summary = false)
      contents = []
      deps.each do |dep|
        if show_summary
          spec = @resolve[dep.name].first.__materialize__
          contents << "#{"  " if inside_group}# #{spec.summary}"
        end

        gem = []
        gem << "  " if inside_group
        gem << gem_contents(dep)
        contents << gem.join
      end
      contents
    end

    # @param [Bundler::Dependency] dep    Dependency instance of the gem
    # @param [Boolean]             groups Whether groups be shown in gem contents
    def gem_contents(dep, groups = false)
      contents = []
      contents << "gem " << dep.name.dump

      contents << ", " << dep.requirement.as_list.map(&:inspect).join(", ") unless dep.requirement.none?

      contents << ", :group#{"s" if dep.groups.uniq.size > 1} => " << dep.groups.uniq.inspect if groups

      contents << ", :source => \"" << dep.source.remotes << "\"" unless dep.source.nil?
      # contents = ["gemspec"] if dep.source.options["gemspec"]

      contents << ", :platforms => " << dep.platforms.inspect unless dep.platforms.empty?

      env = dep.instance_variable_get(:@env)
      contents << ", :env => " << env.inspect if env

      if (req = dep.autorequire) && !req.empty?
        req = req.first if req.size == 1
        contents << ", :require => " << req.inspect
      end

      contents
    end
  end
end
