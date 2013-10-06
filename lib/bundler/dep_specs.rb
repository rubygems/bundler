require 'bundler/dep_fetcher'
require 'bundler/endpoint_specification'
require 'bundler/index'

module Bundler
  class DepSpecs
    NAME_PATTERN = /\A[0-9a-zA-Z_\-][0-9a-zA-Z_\-\.]*\Z/
    VERSION_PATTERN = /\A[0-9]+(?>\.[0-9a-zA-Z]+)*(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?\Z/

    attr_reader :source_uri, :names

    def initialize(source, source_uri = nil)
      @source = source
      @source_uri = source_uri || source.remotes.first
      @dep_fetcher = DepFetcher.new(source_uri)
    end

    def spec_index(names)
      Index.build do |i|
        each_spec(names) { |s| i << s }
      end
    end
    alias_method :specs, :spec_index

    def each_spec(names)
      return unless @dep_fetcher.fetch(names)

      names.each do |name|
        raise "Sorry, #{name} is not a valid gem name" unless name =~ NAME_PATTERN
        each_spec_for(name) { |spec| yield spec }
      end
    end

  private

    def each_spec_for(name)
      each_index_line("deps/#{name}") do |line|
        version, platform, deps, reqs = version_info(line) || next
        spec = EndpointSpecification.new(name, version, platform, deps)
        reqs.each do |req|
          spec.send("required_#{req.name}_version", req.requirement)
        end if reqs
        spec.source = @source
        spec.source_uri = @source_uri
        yield spec
      end
    end

    def each_index_line(filename)
      index_path = Bundler.bundle_path.join(filename)
      index_path.open do |file|
        in_prologue = true
        file.each_line do |line|
          line.chomp!
          in_prologue = false if line == "---"
          yield(line) unless in_prologue
        end
      end
    end

    def version_info(line)
      vp, dr = line.split(' ', 2)
      return unless vp =~ VERSION_PATTERN

      v, p = vp.split("-", 2)
      gv, gp = Gem::Version.new(v), Gem::Platform.new(p)

      if dr
        deps, reqs = dr.split('|').map{|l| l.split(",") }
        gd = deps.map { |d| dependency_info(d) } if deps
        gr = reqs.map { |r| dependency_info(r) } if reqs
      end

      [gv, gp, gd, gr]
    end

    def dependency_info(string)
      name, req_str = string.split(":")
      Gem::Dependency.new(name, req_str.split("&"))
    end

  end
end
