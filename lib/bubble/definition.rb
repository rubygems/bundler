module Bubble
  class Definition
    def self.from_gemfile(gemfile)
      gemfile = Pathname.new(gemfile || default_gemfile).expand_path

      unless gemfile.file?
        raise GemfileNotFound, "`#{gemfile}` not found"
      end

      Dsl.evaluate(gemfile)
    end

    def self.default_gemfile
      current = Pathname.new(Dir.pwd)

      until current.root?
        filename = current.join("Gemfile")
        return filename if filename.exist?
        current = current.parent
      end

      raise GemfileNotFound, "The default Gemfile was not found"
    end

    def self.from_lock(lockfile)
      gemfile_definition = from_gemfile(nil)
      locked_definition = Locked.new(YAML.load_file(lockfile))
      raise GemfileError unless gemfile_definition.equivalent?(locked_definition)
      locked_definition
    end

    attr_reader :dependencies, :sources

    def initialize(dependencies, sources)
      @dependencies = dependencies
      @sources = sources
    end

    def equivalent?(other)
      self.matches?(other) && other.matches?(self)
      # other.matches?(self)
    end

    def matches?(other)
      dependencies.all? do |dep|
        dep =~ other.specs.find {|spec| spec.name == dep.name }
      end
    end

    def specs
      @specs ||= Resolver.resolve(dependencies, index)
    end

    def index
      @index ||= begin
        index = Index.new
        sources.reverse_each do |source|
          index.merge! source.local_specs
        end
        index
      end
    end

    def to_yaml(options = {})
      details.to_yaml(options)
    end

  private

    def details
      {}.tap do |det|
        det["sources"] = sources.map { |s| { s.class.name.split("::").last => s.options} }
        det["specs"] = specs.map { |s| {s.name => s.version.to_s} }
        det["dependencies"] = dependencies.map { |d| {d.name => d.version_requirements.to_s} }
      end
    end

    class Locked < Definition
      def initialize(details)
        @details = details
        raise GemfileError if specs.any? { |s| s.nil? }
      end

      def sources
        @sources ||= @details["sources"].map do |args|
          name, options = args.to_a.flatten
          Bubble::Source.const_get(name).new(options)
        end
      end

      def specs
        @specs ||= @details["specs"].map do |args|
          dep = Gem::Dependency.new(*args.to_a.flatten)
          index.search(dep).first
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