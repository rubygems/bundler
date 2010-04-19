# TODO: In the 0.10 release, there shouldn't be a locked subclass of Definition
module Bundler
  module Flex
    class Definition
      attr_reader :dependencies, :sources

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
        @lockfile, @dependencies, @sources = lockfile, dependencies, sources
      end

      alias resolved_dependencies dependencies

      def groups
        dependencies.map { |d| d.groups }.flatten.uniq
      end

    end
  end
end