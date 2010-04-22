require "strscan"

module Bundler
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

      @sources.uniq!
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

    def parse_source_line(line, extra_opts = {})
      type, source, option_line = line.match(/^\s+(\w+): ([^\s]*?)(?: (.*))?$/).captures
      options = extract_options(option_line)
      # There should only be one instance of a rubygem source
      if type == 'gem'
        rg_source.add_remote source
        rg_source
      else
        TYPES[type].from_lock(source, extra_opts.merge(options))
      end
    end

    def rg_source
      @rg_source ||= Source::Rubygems.new
    end

    NAME_VERSION = '(?! )(.*?)(?: \((.*)\))?:?'

    def parse_dependencies(line)
      if line =~ %r{^ {2}#{NAME_VERSION}$}
        name, version = $1, $2

        if version =~ /^= (.+)$/
          @last_version = $1
        end

        @current = Bundler::Dependency.new(name, version)
        @dependencies << @current
      else
        @current.source = parse_source_line(line, "name" => @current.name, "version" => @last_version)
        @sources.unshift @current.source
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