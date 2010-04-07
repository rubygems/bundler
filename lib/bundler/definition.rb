require "digest/sha1"

# TODO: In the 0.10 release, there shouldn't be a locked subclass of Definition
module Bundler
  class Definition
    def self.from_gemfile(gemfile)
      gemfile = Pathname.new(gemfile).expand_path

      unless gemfile.file?
        raise GemfileNotFound, "#{gemfile} not found"
      end

      Dsl.evaluate(gemfile)
    end

    def self.from_lock(lockfile, check = true)
      return nil unless lockfile.exist?

      locked_definition = Locked.new(YAML.load_file(lockfile))

      if check
        hash = Digest::SHA1.hexdigest(File.read("#{Bundler.root}/Gemfile"))
        unless locked_definition.hash == hash
          raise GemfileError, "You changed your Gemfile after locking. Please relock using `bundle lock`"
        end
      end

      locked_definition
    end

    def self.flexdef(gemfile, lockfile)
      Flex.new(from_gemfile(gemfile), from_lock(lockfile, false))
    end

    attr_reader :dependencies, :sources

    alias resolved_dependencies dependencies

    def initialize(dependencies, sources)
      @dependencies = dependencies
      @sources = sources
    end

    def groups
      dependencies.map { |d| d.groups }.flatten.uniq
    end

    class Flex
      def initialize(gemfile, lockfile)
        @gemfile  = gemfile
        @lockfile = lockfile
      end

      def dependencies
        @gemfile.dependencies
      end

      def sources
        @gemfile.sources
      end

      def groups
        dependencies.map { |d| d.groups }.flatten.uniq
      end

      def resolved_dependencies
        @resolved_dependencies ||= begin
          if @lockfile
            deps = @lockfile.resolved_dependencies.dup

            dependencies.each do |d|
              next if deps.any? { |new_dep| new_dep.name == d.name }
              deps << d
            end

            deps
          else
            dependencies
          end
        end
      end
    end

    class Locked < Definition
      def initialize(details)
        @details = details
      end

      def hash
        @details["hash"]
      end

      def sources
        @sources ||= @details["sources"].map do |args|
          name, options = args.to_a.flatten
          Bundler::Source.const_get(name).new(options)
        end
      end

      def resolved_dependencies
        @resolved_dependencies ||= @details["specs"].map do |args|
          name, details = args.to_a.flatten
          details["source"] = sources[details["source"]] if details.include?("source")
          Bundler::Dependency.new(name, details.delete("version"), details)
        end
      end

      def dependencies
        @dependencies ||= @details["dependencies"].map do |opts|
          Bundler::Dependency.new(opts.delete("name"), opts.delete("version"), opts)
        end
      end
    end
  end
end
