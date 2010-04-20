# TODO: In the 0.10 release, there shouldn't be a locked subclass of Definition
module Bundler
  module Flex
    class Definition
      attr_reader :dependencies, :sources, :locked_specs

      def self.build(gemfile, lockfile)
        gemfile = Pathname.new(gemfile).expand_path

        unless gemfile.file?
          raise GemfileNotFound, "#{gemfile} not found"
        end

        # TODO: move this back into DSL
        builder = Dsl.new
        builder.instance_eval(File.read(gemfile.to_s), gemfile.to_s, 1)
        builder.to_flex_definition(lockfile)
      end

      def initialize(lockfile, dependencies, sources)
        @dependencies, @sources = dependencies, sources

        if lockfile && File.exists?(lockfile)
          locked = LockfileParser.new(File.read(lockfile))
          @locked_specs = locked.specs
        else
          @locked_specs = []
        end
      end

      # TODO: OMG LOL
      def resolved_dependencies
        locked_specs_as_deps + dependencies
      end

      def groups
        dependencies.map { |d| d.groups }.flatten.uniq
      end

      def locked_specs_as_deps
        locked_specs.map { |s| Gem::Dependency.new(s.name, s.version) }
      end
    end
  end
end