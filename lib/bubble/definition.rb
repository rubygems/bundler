module Bubble
  class Definition
    def self.from_gemfile(gemfile)
      gemfile = Pathname.new(gemfile || default_gemfile).expand_path

      unless gemfile.file?
        raise GemfileNotFound, "`#{gemfile}` not found"
      end

      definition = new
      Dsl.evaluate(gemfile, definition)
      definition
    end

    def self.default_gemfile
      current = Pathname.new(Dir.pwd)

      until current.root?
        filename = current.join("Gemfile")
        return filename if filename.exist?
        current = current.parent
      end

      raise GemfileNotFound, "the default Gemfile was not found"
    end

    attr_reader :dependencies, :sources

    def initialize
      @dependencies, @sources = [], Gem.sources.map { |s| Source::Rubygems.new(:uri => s) }
    end
  end
end