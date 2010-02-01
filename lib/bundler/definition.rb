module Bundler
  class Definition
    def self.from_gemfile(gemfile)
      gemfile = Pathname.new(gemfile).expand_path

      unless gemfile.file?
        raise GemfileNotFound, "`#{gemfile}` not found"
      end

      Dsl.evaluate(gemfile)
    end

    def self.from_lock(lockfile)
      # gemfile_definition = from_gemfile(nil)
      locked_definition = Locked.new(YAML.load_file(lockfile))
      # raise GemfileError unless gemfile_definition.equivalent?(locked_definition)
      locked_definition
    end

    attr_reader :dependencies, :sources

    alias actual_dependencies dependencies

    def initialize(dependencies, sources)
      @dependencies = dependencies
      @sources = sources
    end

    def local_index
      @local_index ||= begin
        index = Index.new

        sources.each do |source|
          next unless source.respond_to?(:local_specs)
          index = source.local_specs.merge(index)
        end

        Index.from_installed_gems.merge(index)
      end
    end

    # def equivalent?(other)
    #   self.matches?(other) && other.matches?(self)
    #   # other.matches?(self)
    # end

    # def matches?(other)
    #   dependencies.all? do |dep|
    #     dep =~ other.specs.find {|spec| spec.name == dep.name }
    #   end
    # end

    class Locked < Definition
      def initialize(details)
        @details = details
      end

      def sources
        @sources ||= @details["sources"].map do |args|
          name, options = args.to_a.flatten
          Bundler::Source.const_get(name).new(options)
        end
      end

      def actual_dependencies
        @actual_dependencies ||= @details["specs"].map do |args|
          Gem::Dependency.new(*args.to_a.flatten)
        end
      end

      def dependencies
        @dependencies ||= @details["dependencies"].map do |args|
          Gem::Dependency.new(*args.to_a.flatten)
        end
      end
    end
  end
end