# frozen_string_literal: true

module Bundler
  class Gemfile
    def self.full_gemfile(options = {})
      gemfile = new(options)
      gemfile.full_gemfile
    end

    def initialize(options)
      @options = options
      @resolve = nil
    end

    def full_gemfile
      definition = Bundler.definition
      @resolve = definition.resolve if @options[:show_summary]

      gemfile = []
      Array(definition.send(:sources).global_rubygems_source).each do |s|
        s.remotes.each {|r| gemfile << "source #{r.to_s.dump}" }
      end

      gemfile << nil

      definition.dependencies.group_by(&:groups).each_key(&:sort!).sort_by(&:first).each do |groups, deps|
        groups = nil if groups.empty? || groups.include?(:default)

        group_block = groups && !@options[:inline_groups]
        inside_group = !groups.nil? && !@options[:inline_groups]
        gemfile << "group #{groups.map(&:inspect).uniq.join(", ")} do" if group_block
        gemfile << deps_contents(deps.sort_by(&:name), inside_group)
        gemfile << "end" if group_block
        gemfile << nil
      end

      gemfile
    end

    # @param  [Bundler::Dependency] dep    Dependency instance of the gem
    # @param  [Boolean]             show_groups Whether groups be shown in gem contents
    # @return [[String]]
    def gem_contents(dep, show_groups = false)
      contents = []
      contents << "gem " << dep.name.dump

      contents << ", " << dep.requirement.as_list.map(&:inspect).join(", ") unless dep.requirement.none?

      contents << ", :group#{"s" if dep.groups.uniq.size > 1} => " << dep.groups.uniq.inspect if show_groups || @options[:inline_groups]

      contents << ", :source => \"" << dep.source.remotes << "\"" unless dep.source.nil?
      # contents = ["gemspec"] if @dep.source.options["gemspec"]

      contents << ", :platforms => " << dep.platforms.inspect unless dep.platforms.empty?

      env = dep.instance_variable_get(:@env)
      contents << ", :env => " << env.inspect if env

      if (req = dep.autorequire) && !req.empty?
        req = req.first if req.size == 1
        contents << ", :require => " << req.inspect
      end

      contents
    end

    # @param [[Bundler::Dependency]] deps         Array of dependency instances of gems
    # @param [Boolean]               inside_group Whether gems to be shown are inside group
    # @return [[String]]
    def deps_contents(deps, inside_group = false)
      contents = []
      deps.each do |dep|
        if @options[:show_summary]
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
  end
end
