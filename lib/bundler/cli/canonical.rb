# frozen_string_literal: true

module Bundler
  class CLI::Canonical
    def initialize; end

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

        gemfile << "group #{groups.map(&:inspect).join(", ")} do" if groups

        deps.sort_by(&:name).each do |dep|
          spec = resolve[dep.name].first.__materialize__
          gemfile << "#{"  " if groups}# #{spec.summary}" if spec

          da = []
          da << "  " if groups
          da << "gem " << dep.name.dump

          da << ", " << dep.requirement.as_list.map(&:inspect).join(", ") unless dep.requirement.none?

          unless dep.source.nil?
            da << ", :source => \"" << dep.source.remotes << "\""
            da = ["gemspec"] if dep.source.options["gemspec"]
          end

          da << ", platforms: " << dep.platforms.inspect unless dep.platforms.empty?

          if env = dep.instance_variable_get(:@env)
            da << ", env: " << env.inspect
          end

          if (req = dep.autorequire) && !req.empty?
            req = req.first if req.size == 1
            da << ", require: " << req.inspect
          end

          gemfile << da.join
        end

        gemfile << "end" if groups

        gemfile << nil
      end

      contents = gemfile.join("\n").gsub(/\n{3,}/, "\n\n").strip
      puts contents
      # SharedHelpers.write_to_gemfile(Bundler.default_gemfile, contents)
    end
  end
end
