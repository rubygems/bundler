require "digest/sha1"

module Bundler
  class Definition
    def self.from_gemfile(gemfile)
      gemfile = Pathname.new(gemfile).expand_path

      unless gemfile.file?
        raise GemfileNotFound, "#{gemfile} not found"
      end

      Dsl.evaluate(gemfile)
    end

    def self.from_lock(lockfile)
      locked_definition = Locked.new(YAML.load_file(lockfile))

      hash = Digest::SHA1.hexdigest(File.read("#{Bundler.root}/Gemfile"))
      unless locked_definition.hash == hash
        raise GemfileError, "You changed your Gemfile after locking. Please relock using `bundle lock`"
      end

      locked_definition
    end

    attr_reader :dependencies, :sources

    alias actual_dependencies dependencies

    def initialize(dependencies, sources)
      @dependencies = dependencies
      @sources = sources
    end

    def groups
      dependencies.map { |d| d.groups }.flatten.uniq
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

      def actual_dependencies
        @actual_dependencies ||= @details["specs"].map do |args|
          name, details = args.to_a.flatten
          details["source"] = sources[details["source"]] if details.include?("source")
          Bundler::Dependency.new(name, details.delete("version"), details)
        end
      end

      def dependencies
        @dependencies ||= @details["dependencies"].map do |dep, opts|
          Bundler::Dependency.new(dep, opts.delete("version"), opts)
        end
      end
    end
  end
end
