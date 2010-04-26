require "digest/sha1"

# TODO: In the 0.10 release, there shouldn't be a locked subclass of Definition
module Bundler
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
      builder.to_definition(lockfile)
    end

    def initialize(lockfile, dependencies, sources)
      @dependencies, @sources = dependencies, sources

      if lockfile && File.exists?(lockfile)
        locked = LockfileParser.new(File.read(lockfile))
        @locked_deps  = locked.dependencies
        @locked_specs = SpecSet.new(locked.specs)
        @sources = locked.sources
      else
        @locked_deps  = []
        @locked_specs = SpecSet.new([])
      end
    end

    def index
      @index ||= Index.build do |idx|
        sources.each do |s|
          idx.use s.local_specs
        end
      end
    end

    def remote_index
      @remote_index ||= Index.build do |idx|
        sources.each { |source| idx.use source.specs }
      end
    end

    def no_sources?
      sources.length == 1 && sources.first.remotes.empty?
    end

    # TODO: OMG LOL
    def resolved_dependencies
      deps = locked_specs_as_deps
      dependencies.each do |dep|
        deps << dep unless deps.any? { |d| d.name == dep.name }
      end
      deps
    end

    def groups
      dependencies.map { |d| d.groups }.flatten.uniq
    end

    # We have the dependencies from Gemfile.lock and the dependencies from the
    # Gemfile. Here, we are finding a list of all dependencies that were
    # originally present in the Gemfile that still satisfy the requirements
    # of the dependencies in the Gemfile.lock
    #
    # This allows us to add on the *new* requirements in the Gemfile and make
    # sure that the changes result in a conservative update to the Gemfile.lock.
    def locked_specs_as_deps
      deps = @dependencies & @locked_deps

      @dependencies.each do |dep|
        next if deps.include?(dep)
        deps << dep if @locked_specs.any? { |s| s.satisfies?(dep) }
      end

      meta_deps = @locked_specs.for(deps).map do |s|
        dep = Gem::Dependency.new(s.name, s.version)
        @locked_deps.each do |d|
          dep.source = d.source if d.name == dep.name
        end
        dep
      end
    end
  end
end
