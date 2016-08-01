# frozen_string_literal: true

require "rbconfig"

module Bundler
  class CLI::Doctor
    DARWIN_REGEX = /\s+(.+) \(compatibility /
    LDD_REGEX = /\t\S+ => (\S+) \(\S+\)/

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def otool_available?
      system("otool --version 2>&1 >/dev/null")
    end

    def ldd_available?
      !system("ldd --help 2>&1 >/dev/null").nil?
    end

    def dylibs_darwin(path)
      output = `/usr/bin/otool -L "#{path}"`.chomp
      dylibs = output.split("\n")[1..-1].map {|l| l.match(DARWIN_REGEX).captures[0] }.uniq
      # ignore @rpath and friends
      dylibs.reject {|dylib| dylib.start_with? "@" }
    end

    def dylibs_ldd(path)
      output = `/usr/bin/ldd "#{path}"`.chomp
      output.split("\n").map do |l|
        match = l.match(LDD_REGEX)
        next if match.nil?
        match.captures[0]
      end.compact
    end

    def dylibs(path)
      case RbConfig::CONFIG["host_os"]
      when /darwin/
        return [] unless otool_available?
        dylibs_darwin(path)
      when /(linux|solaris|bsd)/
        return [] unless ldd_available?
        dylibs_ldd(path)
      else # Windows, etc.
        Bundler.ui.warn("Dynamic library check not supported on this platform.")
        []
      end
    end

    def bundles_for_gem(spec)
      Dir.glob("#{spec.full_gem_path}/**/*.bundle")
    end

    def run
      Bundler.ui.level = "error" if options[:quiet]

      broken_links = {}

      begin
        definition = Bundler.definition
        definition.validate_ruby!
        not_installed = definition.missing_specs
        raise GemNotFound if not_installed.any?
      rescue GemNotFound
        Bundler.ui.error "This bundle's gems must be installed to run this command."
        Bundler.ui.warn "Install missing gems with `bundle install`."
        exit 2
      end

      definition.specs.each do |spec|
        bundles_for_gem(spec).each do |bundle|
          bad_paths = dylibs(bundle).select {|f| !File.exist?(f) }
          if bad_paths.any?
            broken_links[spec] ||= []
            broken_links[spec].concat(bad_paths)
          end
        end
      end

      if broken_links.any?
        Bundler.ui.error "The following gems are missing OS dependencies"
        broken_links.each do |spec, paths|
          paths.uniq.each do |path|
            Bundler.ui.error " * #{spec.name}: #{path}"
          end
        end
        exit 1
      end
    end
  end
end
