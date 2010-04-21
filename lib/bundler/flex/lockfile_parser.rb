require "strscan"

module Bundler
  module Flex
    class LockfileParser
      attr_reader :sources, :dependencies, :specs

      # Do stuff
      def initialize(lockfile)
        @sources = []
        @dependencies = []
        @specs = []

        lockfile.split(/\n+/).each do |line|
          case line
          when "sources:"
            @state = :source
          when "dependencies:"
            @state = :dependencies
          when "specs:"
            @state = :specs
          else
            send("parse_#{@state}", line)
          end
        end
      end

    private

      TYPES = {
        "git"  => Bundler::Source::Git,
        "gem"  => Bundler::Source::Rubygems,
        "path" => Bundler::Source::Path
      }

      def parse_source(line)
        @sources << parse_source_line(line)
      end

      def parse_source_line(line)
        type, source, option_line = line.match(/^\s+(\w+): ([^\s]*?)(?: (.*))?$/).captures
        options = extract_options(option_line)
        TYPES[type].from_lock(source, options)
      end

      NAME_VERSION = '(?! )(.*?)(?: \((.*)\))?:?'

      def parse_dependencies(line)
        if line =~ %r{^ {2}#{NAME_VERSION}$}
          name, version = $1, $2

          @current = Bundler::Dependency.new(name, version)
          @dependencies << @current
        else
          @current.source = parse_source_line(line)
        end
      end

      def parse_specs(line)
        if line =~ %r{^ {2}#{NAME_VERSION}$}
          @current = LazySpecification.new($1, $2)
          @specs << @current
        else
          line =~ %r{^ {4}#{NAME_VERSION}$}
          @current.dependencies << Gem::Dependency.new($1, $2)
        end
      end

      def extract_options(line)
        options = {}
        return options unless line

        line.scan(/(\w+):"((?:|.*?[^\\])(?:\\\\)*)" ?/) do |k,v|
          options[k] = v
        end

        options
      end

    end
  end
end