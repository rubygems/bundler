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
      # gemfile_definition = from_gemfile(nil)
      locked_definition = Locked.new(YAML.load_file(lockfile))

      # TODO: Switch to using equivalent?
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
