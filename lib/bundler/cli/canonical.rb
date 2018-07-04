# frozen_string_literal: true

module Bundler
  class CLI::Canonical
    def initialize(options)
      @options = options
    end

    def run
      definition = Bundler.definition
      resolve = definition.resolve

      gemfile = []
      Array(definition.send(:sources).global_rubygems_source).each do |s|
        s.remotes.each {|r| gemfile << "source #{r.to_s.dump}" }
      end

      gemfile << nil

      definition.dependencies.group_by(&:groups).each_key(&:sort!).sort_by(&:first).each do |groups, deps|
        groups = nil if groups.empty? || groups.include?(:default)

        gemfile << "group #{groups.map(&:inspect).uniq.join(", ")} do" if groups

        deps.sort_by(&:name).each do |dep|
          spec = resolve[dep.name].first.__materialize__
          gemfile << "#{"  " if groups}# #{spec.summary}" if spec

          gem = []
          gem << "  " if groups
          gem << gem_contents(dep)

          gemfile << gem.join
        end

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
